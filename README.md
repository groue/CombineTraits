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
- [Tools]

## The SinglePublisher Protocol

**`SinglePublisher` is the protocol for "single publishers". They publish exactly one element, or an error.**

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
            // It is ok is no name was received?
            break
        case let .failure(error):
            // It is ok is a name was received?
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

See also [TraitPublishers.Single] and [SingleSubscription].

### Basic Single Publishers

## The MaybePublisher Protocol

**`MaybePublisher` is the protocol for "maybe publishers". They publish exactly zero element, or one element, or an error.**

```
--------> A maybe publisher can never publish anything.
-----x--> A maybe publisher can fail.
-----|--> A maybe publisher can complete without publishing any value.
--o--|--> A maybe publisher can publish one value and complete.
```

In the Combine framework, the built-in `Empty`, Just`, `Future` and `URLSession.DataTaskPublisher` are examples of publishers that conform to `MaybePublisher`.

Conversely, `Publishers.Sequence` is not a maybe publisher, because not all sequences contain zero or one element.

- [AnyMaybePublisher]
- [`sinkMaybe(receive:)`]
- [Building Maybe Publishers]
- [Basic Maybe Publishers]

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
            // It is ok is a name was received?
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

See also [TraitPublishers.Maybe] and [MaybeSubscription].

### Basic Maybe Publishers

## Tools

- [TraitPublishers.Single]
- [TraitPublishers.Maybe]
- [SingleSubscription]
- [MaybeSubscription]

### TraitPublishers.Single
### TraitPublishers.Maybe
### SingleSubscription
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
