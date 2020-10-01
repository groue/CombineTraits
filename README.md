CombineTraits [![Swift 5.3](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/) [![License](https://img.shields.io/github/license/groue/CombineTraits.svg?maxAge=2592000)](/LICENSE)
=============

### Guarantees on the number of elements published by Combine publishers

**Requirements**: iOS 13.0+ / OSX 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.3+ / Xcode 12.0+

---

## What is this?

CombineTraits solves a problem with the [Combine] framework: publishers do not tell how many elements can be published. It is particularly the case of [AnyPublisher], the publisher type that is the most frequently returned by our frameworks or applications: one must generally assume that it may publish zero, one, or more elements before it completes.

Quite often, we have to rely on the context or the documentation in order to lift doubts. For example, we expect a publisher that publishes the result of some network request to publish only one value, or the eventual network error. We do not deal with odd cases such as a completion without any value, or several published values.

And sometimes, we build a publisher that we *think* will publish a single value before completion. Unfortunately we write bugs and our publisher fails to honor its own contract. This can trigger bugs in other parts of our application.

**In both cases, the compiler did not help us writing code that is guaranteed to be correct.** That's what CombineTraits is about.

This library comes with support for two publisher traits:
        
- **Single** publishers are guaranteed to publish exactly one element, or an error:
    
    ```
    --------> A single publisher can never publish anything.
    -----x--> A single publisher can fail.
    --o--|--> A single publisher can publish one value and complete.
    ```
    
- **Maybe** publishers are guaranteed to publish exactly zero element, or one element, or an error:
    
    ```
    --------> A maybe publisher can never publish anything.
    -----x--> A maybe publisher can fail.
    -----|--> A maybe publisher can complete without publishing any value.
    --o--|--> A maybe publisher can publish one value and complete.
    ```

# Documentation

- [The SinglePublisher Protocol]
- [The MaybePublisher Protocol]

## The SinglePublisher Protocol

**`SinglePublisher` is the protocol for publishers that publish exactly one element, or an error.**

```
--------> A single publisher can never publish anything.
-----x--> A single publisher can fail.
--o--|--> A single publisher can publish one value and complete.
```

In the Combine framework, the built-in `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of publishers that conform to `SinglePublisher`.

Conversely, `Publishers.Sequence` is not a single publisher, because not all sequences contain a single element.

- [AnySinglePublisher]
- [`sinkSingle(receive:)`]
- [Building Single Publishers]
- [Basic Single Publishers]
- [TraitPublishers.Single]
- [SingleSubscription]

#### AnySinglePublisher

`AnySinglePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it publishes exactly one `String`, no more, no less:
    
```swift
/// 😎 Publishes exactly one name
func namePublisher() -> AnySinglePublisher<String, Error>
```

Compare with the regular `AnyPublisher`, where documentation is the only way to express the "single" guarantee:

```swift
/// 🤔 Trust us: this publisher can only publish one name, or an error.
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

#### `sinkSingle(receive:)`

The `sinkSingle(receive:)` method simplifies handling of single publisher results:
    
```swift
// 😎 There are only two cases to handle
let cancellable = namePublisher().sinkSingle { (result: Result<String, Error>) in
    switch result {
    case let .success(name):
        handle(name)
    case let .failure(error):
        handle(error)
    }
}
```

Compare with the regular `sink(receiveCompletion:receiveValue:)`, which contains so many opportunities to misbehave:

```swift
// 🤔 There are a certain amount of cases to handle
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

### Building Single Publishers

In order to benefit from the `SinglePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a single publisher:

- **Compiler-checked single publishers** are publishers that conform to the `SinglePublisher` protocol. This is the case of `Just` and `Fail`, for example. Some publishers conditionally conform to `SinglePublisher`, such as `Publishers.Map`, when the upstream publisher is a single publisher.
    
    When you define a publisher type that publishes exactly one element, or an error, you can turn it into a single publisher with an extension:
    
    ```swift
    struct MySinglePublisher: Publisher { ... }
    extension MySinglePublisher: SinglePublisher { }
    ```

- **Runtime-checked single publishers** are publishers that conform to the `SinglePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly one element, or an error.
    
    You build a checked single publisher with one of those methods:
    
    - `Publisher.checkSingle()` returns a single publisher that fails with a `SingleError` if the upstream publisher does not publish exactly one element, or an error.
    
    - `Publisher.assertSingle()` returns a single publisher that raises a fatal error if the upstream publisher does not publish exactly one element, or an error.

- **Unchecked single publishers**: you should only build such a single publisher when you are sure that the `SinglePublisher` contract is honored by the upstream publisher.
    
    For example:
    
    ```swift
    // CORRECT: those publish exactly one element, or an error.
    [1].publisher.uncheckedSingle()
    [1, 2].publisher.prefix(1).uncheckedSingle()
    
    // WRONG: does not publish any element
    Empty().uncheckedSingle()
    
    // WRONG: publishes more than one element
    [1, 2].publisher.uncheckedSingle()
    
    // WRONG: does not publish exactly one element, or an error
    Just(1).append(Fail(error)).uncheckedSingle()
    
    // WARNING: may not publish exactly one element, or an error
    someSubject.prefix(1).uncheckedSingle()
    ```swift
    
    The consequences of using `uncheckedSingle()` on a publisher that does not publish exactly one element, or an error, are undefined.

See also [Basic Single Publishers], [TraitPublishers.Single] and [SingleSubscription].

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

### TraitPublishers.Single
### SingleSubscription

## The MaybePublisher Protocol

**`MaybePublisher` is the protocol for publishers that publish exactly zero element, or one element, or an error.**

```
--------> A maybe publisher can never publish anything.
-----x--> A maybe publisher can fail.
-----|--> A maybe publisher can complete without publishing any value.
--o--|--> A maybe publisher can publish one value and complete.
```

In the Combine framework, the built-in `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of publishers that conform to `MaybePublisher`.

Conversely, `Publishers.Sequence` is not a maybe publisher, because not all sequences contain zero or one element.

- [AnyMaybePublisher]
- [`sinkMaybe(receive:)`]
- [Building Maybe Publishers]
- [Basic Maybe Publishers]
- [TraitPublishers.Maybe]
- [MaybeSubscription]

#### AnyMaybePublisher

`AnyMaybePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it publishes exactly zero or one `String`, no more, no less:
    
```swift
/// 😎 Maybe publishes a name
func namePublisher() -> AnyMaybePublisher<String, Error>
```

Compare with the regular `AnyPublisher`, where documentation is the only way to express the "maybe" guarantee:

```swift
/// 🤔 Trust us: this publisher can only publish zero or one name, or an error.
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

#### `sinkMaybe(receive:)`

The `sinkMaybe(receive:)` method simplifies handling of maybe publisher results:
    
```swift
// 😎 There are only three cases to handle
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

Compare with the regular `sink(receiveCompletion:receiveValue:)`, which contains so many opportunities to misbehave:

```swift
// 🤔 There are a certain amount of cases to handle
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
    
    When you define a publisher type that publishes exactly zero element, or one element, or an error, you can turn it into a maybe publisher with an extension:
    
    ```swift
    struct MyMaybePublisher: Publisher { ... }
    extension MyMaybePublisher: MaybePublisher { }
    ```

- **Runtime-checked maybe publishers** are publishers that conform to the `MaybePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly zero element, or one element, or an error.
    
    You build a checked maybe publisher with one of those methods:
    
    - `Publisher.checkMaybe()` returns a maybe publisher that fails with a `MaybeError` if the upstream publisher does not publish exactly zero element, or one element, or an error.
       
    - `Publisher.assertMaybe()` returns a maybe publisher that raises a fatal error if the upstream publisher does not publish exactly zero element, or one element, or an error.

- **Unchecked maybe publishers**: you should only build such a maybe publisher when you are sure that the `MaybePublisher` contract is honored by the upstream publisher.
    
    For example:
    
    ```swift
    // CORRECT: those publish exactly zero element, or one element, or an error.
    Array<Int>().publisher.uncheckedMaybe()
    [1].publisher.uncheckedMaybe()
    [1, 2].publisher.prefix(1).uncheckedMaybe()
    someSubject.prefix(1).uncheckedMaybe()
    
    // WRONG: publishes more than one element
    [1, 2].publisher.uncheckedMaybe()
    
    // WRONG: does not publish exactly zero element, or one element, or an error
    Just(1).append(Fail(error)).uncheckedMaybe()
    ```
    
    The consequences of using `uncheckedMaybe()` on a publisher that does not publish exactly zero element, or one element, or an error, are undefined.

See also [Basic Maybe Publishers], [TraitPublishers.Maybe] and [MaybeSubscription].

### Basic Maybe Publishers

`AnyMaybePublisher` comes with factory methods that build basic maybe publishers:

```swift
// Completes without publishing any value.
AnyMaybePublisher.empty

// Publishes one value, and then completes.
AnyMaybePublisher.just(value)

// Fails with the given error.
AnyMaybePublisher.fail(error)

// Never publishes any value, never completes.
AnyMaybePublisher.never()
```

### TraitPublishers.Maybe
### MaybeSubscription


[AnyPublisher]: https://developer.apple.com/documentation/combine/anypublisher
[Combine]: https://developer.apple.com/documentation/combine
[Release Notes]: CHANGELOG.md
[The SinglePublisher Protocol]: #the-singlepublisher-protocol
[AnySinglePublisher]: #anysinglepublisher
[`sinkSingle(receive:)`]: #sinksinglereceive
[Building Single Publishers]: #building-single-publishers
[Basic Single Publishers]: #basic-single-publishers
[The MaybePublisher Protocol]: #the-maybepublisher-protocol
[AnyMaybePublisher]: #anymaybepublisher
[`sinkMaybe(receive:)`]: #sinkmaybereceive
[Building Maybe Publishers]: #building-maybe-publishers
[Basic Maybe Publishers]: #basic-maybe-publishers
[Tools]: #Tools
[TraitPublishers.Single]: #traitpublisherssingle
[TraitPublishers.Maybe]: #traitpublishersmaybe
[SingleSubscription]: #singlesubscription
[MaybeSubscription]: #maybesubscription
