Single Publishers
=================

**`SinglePublisher` is the protocol for publishers that publish exactly one value, or an error.**

```
--------> A single publisher can never publish anything.
-----x--> A single publisher can fail before publishing any value.
--o--|--> A single publisher can publish one value and complete.
```

When you import CombineTraits, many Combine publishers are extended with conformance to this protocol, such as `Just`, `Future` and `URLSession.DataTaskPublisher`. Other publishers are conditionally extended, such as `Publishers.Map` or `Publishers.FlatMap`.

Conversely, some publishers such as `Publishers.Sequence` are not extended with `SinglePublisher`, because not all sequences contain a single value.

- [AnySinglePublisher]: a replacement for `AnyPublisher`
- [`sinkSingle(receive:)`]: easy consumption of single publishers
- [Composing Single Publishers]
- [Building Single Publishers]

## AnySinglePublisher

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

Don't miss [Basic Single Publishers] for some handy shortcuts. The above publisher can be written as:

```swift
func namePublisher() -> AnySinglePublisher<String, Error> {
    .just("Alice")
}
```

## `sinkSingle(receive:)`

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

## Composing Single Publishers

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

## Building Single Publishers

In order to benefit from the `SinglePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a single publisher:

- **Compiler-checked single publishers** are publishers that conform to the `SinglePublisher` protocol. This is the case of `Just` and `Fail`, for example. Some publishers conditionally conform to `SinglePublisher`, such as `Publishers.Map`, when the upstream publisher is a single publisher.
    
    When you define a publisher type that publishes exactly one value, or an error, you can turn it into a single publisher with an extension:
    
    ```swift
    struct MySinglePublisher: Publisher { ... }
    extension MySinglePublisher: SinglePublisher { }
    ```

- **Runtime-checked single publishers** are publishers that conform to the `SinglePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly one value, or an error.
    
    `Publisher.assertSingle()` returns a single publisher that raises a fatal error if the upstream publisher does not publish exactly one value, or an error.
        
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

See also [Basic Single Publishers], [TraitPublishers.Single] and [TraitSubscriptions.Single].

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

### TraitPublishers.Single

`TraitPublishers.Single` is a ready-made Combine [Publisher] which which allows you to dynamically send success or failure events.

It lets you easily create custom single publishers to wrap any non-publisher asynchronous work.

You create this publisher by providing a closure. This closure runs when the publisher is subscribed to. It returns a cancellable object in which you define any cleanup actions to execute when the publisher completes, or when the subscription is canceled.

```swift
let publisher = TraitPublishers.Single<String, MyError> { promise in
    // Eventually send completion event, now or in the future:
    promise(.success("Alice"))
    // OR
    promise(.failure(MyError()))
    
    return AnyCancellable { 
        // Perform cleanup
    }
}
```

`TraitPublishers.Single` can be seen as a "deferred future" single publisher:

- Nothing happens until the publisher is subscribed to. A new job starts on each subscription.
- It can complete right on subscription, or at any time in the future.

When needed, `TraitPublishers.Single` can forward its job to another single publisher:

```swift
let publisher = TraitPublishers.Single<String, MyError> { promise in
    return otherSinglePublisher.sinkSingle(receive: promise)
}
```

### TraitSubscriptions.Single

`TraitSubscriptions.Single` is a ready-made Combine [Subscription] that helps you building single publishers that wrap complex asynchronous apis:

```swift
open class Single<Downstream: Subscriber, Context>: NSObject, Subscription {
    public init(downstream: Downstream, context: Context)
    
    /// Subclasses must override and eventually call the `receive` function
    open func start(with context: Context) { }
    
    /// Subclasses can override and perform eventual cleanup after the
    /// subscription was cancelled.
    open func didCancel(with context: Context) { }
    
    public func receive(_ result: Result<Downstream.Input, Downstream.Failure>)
}
```

It is designed to be subclassed. Your custom subscriptions will override the `start(with:)` method in order to start their job, call the `receive(_:)` method in order to complete, and override `didCancel(with:)` when they should perform cancellation cleanup. Use `context` in order to pass any useful information.

For example, let's build a single publisher that lets a user pick a phone number from their address book. This publisher defines a subscription that subclasses `TraitSubscriptions.Single`:

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
        TraitSubscriptions.Single<Downstream, UIViewController>,
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

[AnySinglePublisher]: #anysinglepublisher
[`sinkSingle(receive:)`]: #sinksinglereceive
[Composing Single Publishers]: #composing-single-publishers
[Building Single Publishers]: #building-single-publishers
[Basic Single Publishers]: #basic-single-publishers
[TraitPublishers.Single]: #TraitPublisherssingle
[TraitSubscriptions.Single]: #traitsubscriptionssingle
[Publisher]: https://developer.apple.com/documentation/combine/publisher
[Subscription]: https://developer.apple.com/documentation/combine/subscription
