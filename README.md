CombineTraits [![Swift 5.3](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/) [![License](https://img.shields.io/github/license/groue/CombineTraits.svg?maxAge=2592000)](/LICENSE)
=============

### Guarantees on the number of values published by Combine publishers

**Requirements**: iOS 13.0+ / OSX 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.3+ / Xcode 12.0+

---

<p align="center">
    <a href="#usage">👀 Usage</a> &bull;
    <a href="#documentation">📗 Documentation</a>
</p>

---

## What is this?

One must generally assume that [Combine] publishers may publish zero, one, or more values before they complete. It is particularly the case of [AnyPublisher], frequently returned by our frameworks or applications.

When we deal with publishers that are expected to publish no more than one value, such as network requests for example, we often neglect to deal with edge cases such as a completion without any value, or several published values.

The trouble is that the guarantees about the number of published vales are implicit, subject to interpretation, misunderstandings, wrong documentation, and buggy implementations.

**The compiler does not help us writing code that is guaranteed to be correct.**

This library provides both safe *subscription* and *construction* of publishers that explicitly conform to specific traits:
        
- **[Single Publishers]** are guaranteed to publish exactly one value, or an error.
    
    The Combine `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> A single publisher can never publish anything.
    -----x--> A single publisher can fail before publishing any value.
    --o--|--> A single publisher can publish one value and complete.
    ```
    
- **[Maybe Publishers]** are guaranteed to publish exactly zero value, or one value, or an error:
    
    The Combine `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> A maybe publisher can never publish anything.
    -----x--> A maybe publisher can fail before publishing any value.
    -----|--> A maybe publisher can complete without publishing any value.
    --o--|--> A maybe publisher can publish one value and complete.
    ```

## Usage

**CombineTraits carefully preserves the general ergonomics of Combine.** Your application still deals with regular Combine publishers and operators.

Your applications and libraries will often replace `AnyPublisher` with `AnySinglePublisher` or `AnyMaybePublisher`...
    
```diff
 func downloadPublisher()
--> AnyPublisher<APIModel, Error>
+-> AnySinglePublisher<APIModel, Error>
 { ... }

 func savePublisher(_ model: Model)
--> AnyPublisher<Void, Error>
+-> AnySinglePublisher<Void, Error>
 { ... }

 func refreshPublisher()
--> AnyPublisher<Void, Error> 
+-> AnySinglePublisher<Void, Error>
 {
     downloadPublisher()
         .map { apiModel in Model(apiModel) }
         .flatMap { model in savePublisher(model) }
-        .eraseToAnyPublisher()
+        .eraseToAnySinglePublisher()
 }
```

... and replace `sink` with `sinkSingle` or `sinkMaybe`:
    
```diff
-let cancellable = refreshPublisher().sink(receiveCompletion:..., receiveValue: ...)
+let cancellable = refreshPublisher().sinkSingle { result in
+    switch result {
+    case .success: ...
+    case let .failure(error): ...
+    }
+}
```

# Documentation

- [Single Publishers]
- [Maybe Publishers]

## Single Publishers

**`SinglePublisher` is the protocol for publishers that publish exactly one value, or an error.**

```
--------> A single publisher can never publish anything.
-----x--> A single publisher can fail before publishing any value.
--o--|--> A single publisher can publish one value and complete.
```

This library extends many Combine publishers with this protocol, such as `Just`, `Future` and `URLSession.DataTaskPublisher`.

Conversely, `Publishers.Sequence` is not a single publisher, because not all sequences contain a single value.

- [AnySinglePublisher]
- [`sinkSingle(receive:)`]
- [Composing Single Publishers]
- [Building Single Publishers]
- [Basic Single Publishers]
- [PublisherTraits.Single]
- [SingleSubscription]

### AnySinglePublisher

`AnySinglePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it publishes exactly one `String`, no more, no less:
    
```swift
/// 👍 Publishes exactly one name
func namePublisher() -> AnySinglePublisher<String, Error>
```

Compare with the regular `AnyPublisher`, where documentation is the only way to express the "single" guarantee:

```swift
/// 😥 Trust us: this publisher can only publish one name, or an error.
func namePublisher() -> AnyPublisher<String, Error>
```

You build an `AnySinglePublisher` with the `SinglePublisher.eraseToAnySinglePublisher()` method. For example:

```swift
func namePublisher() -> AnySinglePublisher<String, Error> {
    Just("Alice")
        .setFailureType(to: Error.self)
        .eraseToAnySinglePublisher()
}
```

Don't miss [Basic Single Publishers] for some handy shortcuts:

```swift
func namePublisher() -> AnySinglePublisher<String, Error> {
    .just("Alice")
}
```

### `sinkSingle(receive:)`

The `sinkSingle(receive:)` method simplifies handling of single publisher results:
    
```swift
// 👍 There are only two cases to handle
let cancellable = namePublisher().sinkSingle { (result: Result<String, Error>) in
    switch result {
    case let .success(name):
        handle(name)
    case let .failure(error):
        handle(error)
    }
}
```

Compare with the regular `sink(receiveCompletion:receiveValue:)`, which has so many opportunities for misbehavior:

```swift
// 😥 There are a certain amount of cases to handle
let cancellable = namePublisher().sink(
    receiveCompletion: { completion in
        switch completion {
        case .finished:
            // It is ok if no name was received before completion?
            break
        case let .failure(error):
            // It is ok if a name was received before the failure?
            handle(error)
        }
    },
    receiveValue: { name in
        // It is ok to receive several names?
        handle(name)
    })
}
```

### Composing Single Publishers

**Single publishers compose well together.**

For example, in the sample code below, we build a new single publisher from several other ones. Note how:

- Both the Combine `map` and `flatMap` methods did not lose the single trait.
- The final `eraseToAnySinglePublisher()` method is only available because the compiler could prove that we combine single publishers in a way that is guaranteed to build a new single publisher.

```swift
/// A publisher that downloads some API model
func downloadPublisher() -> AnySinglePublisher<APIModel, Error> { ... }

/// A publisher that saves a model on disk
func savePublisher(_ model: Model) -> AnySinglePublisher<Void, Error> { ... }

/// A publisher that downloads and saves
func refreshPublisher() -> AnySinglePublisher<Void, Error> {
    downloadPublisher()
        .map { apiModel in Model(apiModel) }
        .flatMap { model in savePublisher(model) }
        .eraseToAnySinglePublisher()
}
```

> :bulb: **Tip**: As soon as you can call the `eraseToAnySinglePublisher()` method, you are sure that you have built a single publisher that will honor its contract.

### Building Single Publishers

In order to benefit from the `SinglePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a single publisher:

- **Compiler-checked single publishers** are publishers that conform to the `SinglePublisher` protocol. This is the case of `Just` and `Fail`, for example. Some publishers conditionally conform to `SinglePublisher`, such as `Publishers.Map`, when the upstream publisher is a single publisher.
    
    When you define a publisher type that publishes exactly one value, or an error, you can turn it into a single publisher with an extension:
    
    ```swift
    struct MySinglePublisher: Publisher { ... }
    extension MySinglePublisher: SinglePublisher { }
    ```

- **Runtime-checked single publishers** are publishers that conform to the `SinglePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly one value, or an error.
    
    You build a checked single publisher with one of those methods:
    
    - `Publisher.checkSingle()` returns a single publisher that fails with a `SingleError` if the upstream publisher does not publish exactly one value, or an error.
    
    - `Publisher.assertSingle()` returns a single publisher that raises a fatal error if the upstream publisher does not publish exactly one value, or an error.
        
        For example:
        
        ```swift
        let nameSubject: CurrentValueSubject<String, Never> = ...
        
        func namePublisher() -> AnySinglePublisher<String, Never> {
            // Safe as long as the subject never finishes:
            subject.prefix(1).assertSingle().eraseToAnySinglePublisher()
        }
        ```

- **Unchecked single publishers**: you should only build such a single publisher when you are sure that the `SinglePublisher` contract is honored by the upstream publisher.
    
    For example:
    
    ```swift
    // CORRECT: those publish exactly one value, or an error.
    [1].publisher.uncheckedSingle()
    [1, 2].publisher.prefix(1).uncheckedSingle()
    
    // WRONG: does not publish any value
    Empty().uncheckedSingle()
    
    // WRONG: publishes more than one value
    [1, 2].publisher.uncheckedSingle()
    
    // WRONG: does not publish exactly one value, or an error
    Just(1).append(Fail(error)).uncheckedSingle()
    
    // WARNING: may not publish exactly one value, or an error
    someSubject.prefix(1).uncheckedSingle()
    ```
    
    The consequences of using `uncheckedSingle()` on a publisher that does not publish exactly one value, or an error, are undefined.

See also [Basic Single Publishers], [PublisherTraits.Single] and [SingleSubscription].

### Basic Single Publishers

`AnySinglePublisher` comes with factory methods that build basic single publishers:

```swift
// Publishes one value, and then completes.
AnySinglePublisher.just(value)

// Fails with the given error.
AnySinglePublisher.fail(error)

// Never publishes any value, never completes.
AnySinglePublisher.never()
```

They are quite handy:

```swift
func namePublisher() -> AnySinglePublisher<String, Error> {
    .just("Alice")
}
```

### PublisherTraits.Single

`PublisherTraits.Single` is a single publisher which allows you to dynamically send success or failure events.

It lets you easily create custom single publishers to wrap any non-publisher asynchronous work.

You create this publisher by providing a closure. This closure runs when the publisher is subscribed to. It returns a cancellable object in which you define any cleanup actions to execute when the publisher completes, or when the subscription is canceled.

```swift
let publisher = PublisherTraits.Single<String, MyError> { promise in
    // Eventually send completion event, now or in the future:
    promise(.success("Alice"))
    // OR
    promise(.failure(MyError()))
    
    return AnyCancellable { 
        // Perform cleanup
    }
}
```

`PublisherTraits.Single` can be seen as a "deferred future" single publisher:

- Nothing happens until the publisher is subscribed to. A new job starts on each subscription.
- It can complete right on subscription, or at any time in the future.

When needed, `PublisherTraits.Single` can forward its job to another single publisher:

```swift
let publisher = PublisherTraits.Single<String, MyError> { promise in
    return otherSinglePublisher.sinkSingle(receive: promise)
}
```

### SingleSubscription

`SingleSubscription` is a ready-made Combine Subscription that helps you building single publishers that wrap complex asynchronous apis.

```swift
open class SingleSubscription<Downstream: Subscriber, Context>: NSObject, Subscription {
    public init(downstream: Downstream, context: Context)
    
    /// Subclasses must override and eventually call the `receive` function
    open func start(with context: Context) { }
    
    /// Subclasses can override and perform eventual cleanup after the
    /// subscription was cancelled.
    open func didCancel(with context: Context) { }
    
    public func receive(_ result: Result<Downstream.Input, Downstream.Failure>)
}
```

It is designed to be subclassed. Your custom subscriptions will override the `start(with:)` method in order to start their job, call the `receive(_:)` method in order to complete, and override `didCancel(with:)` when they should perform cancellation cleanup.

For example, let's build a publisher that lets a user pick a phone number from their address book:

```swift
import Combine
import CombineTraits
import ContactsUI
import UIKit

/// A publisher that presents the contact picker and lets the user pick
/// a phone number.
///
/// It publishes a phone number, or nil if the user dismisses the contact
/// picker without making any choice.
///
/// It must be subscribed from the main thread.
struct PhoneNumberPublisher: SinglePublisher {
    typealias Output = CNPhoneNumber?
    typealias Failure = Never
    
    let viewController: UIViewController
    
    init(presentingContactPickerFrom viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(
            downstream: subscriber,
            context: viewController)
        subscriber.receive(subscription: subscription)
    }
    
    private class Subscription<Downstream: Subscriber>:
        SingleSubscription<Downstream, UIViewController>,
        CNContactPickerDelegate
    where
        Downstream.Input == Output,
        Downstream.Failure == Failure
    {
        override func start(with viewController: UIViewController) {
            let contactPicker = CNContactPickerViewController()
            contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            contactPicker.delegate = self
            viewController.present(contactPicker, animated: true, completion: nil)
        }
        
        override func didCancel(with viewController: UIViewController) {
            viewController.dismiss(animated: true)
        }
        
        // CNContactPickerDelegate
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            receive(.success(nil))
        }
        
        // CNContactPickerDelegate
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if let phoneNumber = contactProperty.value as? CNPhoneNumber {
                receive(.success(phoneNumber))
            }
        }
    }
}

// Usage:

class MyViewController: UIViewController {
    @IBAction func pickPhoneNumber() {
        PhoneNumberPublisher(presentingContactPickerFrom: self)
            .sink { contact in
                // handle contact
            }
            .store(in: &cancellables)
    }
}
```


## Maybe Publishers

**`MaybePublisher` is the protocol for publishers that publish exactly zero value, or one value, or an error.**

```
--------> A maybe publisher can never publish anything.
-----x--> A maybe publisher can fail before publishing any value.
-----|--> A maybe publisher can complete without publishing any value.
--o--|--> A maybe publisher can publish one value and complete.
```

This library extends many Combine publishers with this protocol, such as `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher`.

Conversely, `Publishers.Sequence` is not a maybe publisher, because not all sequences contain zero or one value.

- [AnyMaybePublisher]
- [`sinkMaybe(receive:)`]
- [Building Maybe Publishers]
- [Basic Maybe Publishers]
- [PublisherTraits.Maybe]
- [MaybeSubscription]

### AnyMaybePublisher

`AnyMaybePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it publishes exactly zero or one `String`, no more, no less:
    
```swift
/// 👍 Maybe publishes a name
func namePublisher() -> AnyMaybePublisher<String, Error>
```

Compare with the regular `AnyPublisher`, where documentation is the only way to express the "maybe" guarantee:

```swift
/// 😥 Trust us: this publisher can only publish zero or one name, or an error.
func namePublisher() -> AnyPublisher<String, Error>
```

You build an `AnyMaybePublisher` with the `MaybePublisher.eraseToAnyMaybePublisher()` method. For example:

```swift
func namePublisher() -> AnyMaybePublisher<String, Error> {
    Just("Alice")
        .setFailureType(to: Error.self)
        .eraseToAnyMaybePublisher()
}
```

Don't miss [Basic Maybe Publishers] for some handy shortcuts:

```swift
func namePublisher() -> AnyMaybePublisher<String, Error> {
    .just("Alice")
}
```

### `sinkMaybe(receive:)`

The `sinkMaybe(receive:)` method simplifies handling of maybe publisher results:
    
```swift
// 👍 There are only three cases to handle
let cancellable = namePublisher().sinkMaybe { (result: MaybeResult<String, Error>) in
    switch result {
    case let .empty:
        handleNoName()
    case let .success(name):
        handle(name)
    case let .failure(error):
        handle(error)
    }
}
```

Compare with the regular `sink(receiveCompletion:receiveValue:)`, which has so many opportunities for misbehavior:

```swift
// 😥 There are a certain amount of cases to handle
var nameReceived = false
let cancellable = namePublisher().sink(
    receiveCompletion: { completion in
        switch completion {
        case .finished:
            // Is the `nameReceived` variable thread-safe?
            if !nameReceived {
                handleNoName()
            }
        case let .failure(error):
            // It is ok if a name was received before the failure?
            handle(error)
        }
    },
    receiveValue: { name in
        // It is ok to receive several names?
        // Is the `nameReceived` variable thread-safe?
        nameReceived = true
        handle(name)
    })
}
```

### Building Maybe Publishers

In order to benefit from the `MaybePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a maybe publisher:

- **Compiler-checked maybe publishers** are publishers that conform to the `MaybePublisher` protocol. This is the case of `Empty`, `Just` and `Fail`, for example. Some publishers conditionally conform to `MaybePublisher`, such as `Publishers.Map`, when the upstream publisher is a maybe publisher.
    
    When you define a publisher type that publishes exactly zero value, or one value, or an error, you can turn it into a maybe publisher with an extension:
    
    ```swift
    struct MyMaybePublisher: Publisher { ... }
    extension MyMaybePublisher: MaybePublisher { }
    ```

- **Runtime-checked maybe publishers** are publishers that conform to the `MaybePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly zero value, or one value, or an error.
    
    You build a checked maybe publisher with one of those methods:
    
    - `Publisher.checkMaybe()` returns a maybe publisher that fails with a `MaybeError` if the upstream publisher does not publish exactly zero value, or one value, or an error.
    
    - `Publisher.assertMaybe()` returns a maybe publisher that raises a fatal error if the upstream publisher does not publish exactly zero value, or one value, or an error.
        
        For example:
        
        ```swift
        let nameSubject: CurrentValueSubject<String, Never> = ...
        
        func namePublisher() -> AnyMaybePublisher<String, Never> {
            subject.prefix(1).assertMaybe().eraseToAnyMaybePublisher()
        }
        ```

- **Unchecked maybe publishers**: you should only build such a maybe publisher when you are sure that the `MaybePublisher` contract is honored by the upstream publisher.
    
    For example:
    
    ```swift
    // CORRECT: those publish exactly zero value, or one value, or an error.
    Array<Int>().publisher.uncheckedMaybe()
    [1].publisher.uncheckedMaybe()
    [1, 2].publisher.prefix(1).uncheckedMaybe()
    someSubject.prefix(1).uncheckedMaybe()
    
    // WRONG: publishes more than one value
    [1, 2].publisher.uncheckedMaybe()
    
    // WRONG: does not publish exactly zero value, or one value, or an error
    Just(1).append(Fail(error)).uncheckedMaybe()
    ```
    
    The consequences of using `uncheckedMaybe()` on a publisher that does not publish exactly zero value, or one value, or an error, are undefined.

See also [Basic Maybe Publishers], [PublisherTraits.Maybe] and [MaybeSubscription].

### Basic Maybe Publishers

`AnyMaybePublisher` comes with factory methods that build basic maybe publishers:

```swift
// Completes without publishing any value.
AnyMaybePublisher.empty()

// Publishes one value, and then completes.
AnyMaybePublisher.just(value)

// Fails with the given error.
AnyMaybePublisher.fail(error)

// Never publishes any value, never completes.
AnyMaybePublisher.never()
```

They are quite handy:

```swift
func namePublisher() -> AnyMaybePublisher<String, Error> {
    .just("Alice")
}
```

### PublisherTraits.Maybe

`PublisherTraits.Maybe` is a maybe publisher which allows you to dynamically send success or failure events.

It lets you easily create custom single publishers to wrap any non-publisher asynchronous work.

You create this publisher by providing a closure. This closure runs when the publisher is subscribed to. It returns a cancellable object in which you define any cleanup actions to execute when the publisher completes, or when the subscription is canceled.

```swift
let publisher = PublisherTraits.Maybe<String, MyError> { promise in
    // Eventually send completion event, now or in the future:
    promise(.empty)
    // OR
    promise(.success("Alice"))
    // OR
    promise(.failure(MyError()))
    
    return AnyCancellable { 
        // Perform cleanup
    }
}
```

`PublisherTraits.Maybe` is a "deferred" maybe publisher:

- Nothing happens until the publisher is subscribed to. A new job starts on each subscription.
- It can complete right on subscription, or at any time in the future.

When needed, `PublisherTraits.Maybe` can forward its job to another maybe publisher:

```swift
let publisher = PublisherTraits.Maybe<String, MyError> { promise in
    return otherMaybePublisher.sinkMaybe(receive: promise)
}
```

### MaybeSubscription

`MaybeSubscription` is a ready-made Combine Subscription that helps you building maybe publishers that wrap complex asynchronous apis.

```swift
open class MaybeSubscription<Downstream: Subscriber, Context>: NSObject, Subscription {
    public init(downstream: Downstream, context: Context)
    
    /// Subclasses must override and eventually call the `receive` function
    open func start(with context: Context) { }
    
    /// Subclasses can override and perform eventual cleanup after the
    /// subscription was cancelled.
    open func didCancel(with context: Context) { }
    
    public func receive(_ result: MaybeResult<Downstream.Input, Downstream.Failure>)
}
```

It is designed to be subclassed. Your custom subscriptions will override the `start(with:)` method in order to start their job, call the `receive(_:)` method in order to complete, and override `didCancel(with:)` when they should perform cancellation cleanup.

For example, let's build a publisher that lets a user pick a phone number from their address book:

```swift
import Combine
import CombineTraits
import ContactsUI
import UIKit

/// A publisher that presents the contact picker and lets the user pick
/// a phone number.
///
/// It publishes a phone number, or nothing if the user dismisses the contact
/// picker without making any choice.
///
/// It must be subscribed from the main thread.
struct PhoneNumberPublisher: MaybePublisher {
    typealias Output = CNPhoneNumber
    typealias Failure = Never
    
    let viewController: UIViewController
    
    init(presentingContactPickerFrom viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(
            downstream: subscriber,
            context: viewController)
        subscriber.receive(subscription: subscription)
    }
    
    private class Subscription<Downstream: Subscriber>:
        MaybeSubscription<Downstream, UIViewController>,
        CNContactPickerDelegate
    where
        Downstream.Input == Output,
        Downstream.Failure == Failure
    {
        override func start(with viewController: UIViewController) {
            let contactPicker = CNContactPickerViewController()
            contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            contactPicker.delegate = self
            viewController.present(contactPicker, animated: true, completion: nil)
        }
        
        override func didCancel(with viewController: UIViewController) {
            viewController.dismiss(animated: true)
        }
        
        // CNContactPickerDelegate
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            receive(.empty)
        }
        
        // CNContactPickerDelegate
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if let phoneNumber = contactProperty.value as? CNPhoneNumber {
                receive(.success(phoneNumber))
            }
        }
    }
}

// Usage:

class MyViewController: UIViewController {
    @IBAction func pickPhoneNumber() {
        PhoneNumberPublisher(presentingContactPickerFrom: self)
            .sinkMaybe { result in
                // handle result
            }
            .store(in: &cancellables)
    }
}
```


[AnyPublisher]: https://developer.apple.com/documentation/combine/anypublisher
[Combine]: https://developer.apple.com/documentation/combine
[Release Notes]: CHANGELOG.md
[Single Publishers]: #single-publishers
[AnySinglePublisher]: #anysinglepublisher
[`sinkSingle(receive:)`]: #sinksinglereceive
[Composing Single Publishers]: #composing-single-publishers
[Building Single Publishers]: #building-single-publishers
[Basic Single Publishers]: #basic-single-publishers
[Maybe Publishers]: #maybe-publishers
[AnyMaybePublisher]: #anymaybepublisher
[`sinkMaybe(receive:)`]: #sinkmaybereceive
[Building Maybe Publishers]: #building-maybe-publishers
[Basic Maybe Publishers]: #basic-maybe-publishers
[Tools]: #Tools
[PublisherTraits.Single]: #publishertraitssingle
[PublisherTraits.Maybe]: #publishertraitsmaybe
[SingleSubscription]: #singlesubscription
[MaybeSubscription]: #maybesubscription
