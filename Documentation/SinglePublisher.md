SinglePublisher
===============

**`SinglePublisher` is the protocol for publishers that publish exactly one value, or an error.**

```swift
/// --------> can never publish anything, never complete.
/// -----x--> can fail before publishing any value.
/// --o--|--> can publish one value and complete.
protocol SinglePublisher: MaybePublisher { }
```

All single publishers are also [maybe](MaybePublisher.md) publishers.

When you import CombineTraits, many Combine publishers are extended with conformance to `SinglePublisher`, such as `Just`, `Future` and `URLSession.DataTaskPublisher`. Other publishers are conditionally extended, such as `Publishers.Map` or `Publishers.FlatMap`.

Conversely, some publishers such as `Publishers.Sequence` are not extended with `SinglePublisher`, because not all sequences contain a single value.

- [AnySinglePublisher]: a replacement for `AnyPublisher`
- [`sinkSingle(receive:)`]: easy consumption of single publishers
- [Composing Single Publishers]
- [Building Single Publishers]

## AnySinglePublisher

`AnySinglePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it certainly publishes exactly one `String`, no more, no less:
    
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
    
    let singlePublisher = MySinglePublisher().eraseToAnySinglePublisher()
    let cancellable = MySinglePublisher().sinkSingle { result in ... }
    ```

- **Runtime-checked single publishers** are publishers that conform to the `SinglePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly one value, or an error.
    
    `Publisher.assertSingle()` returns a single publisher that raises a fatal error if the upstream publisher does not honor the contract.
        
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

[AnySinglePublisher]: #anysinglepublisher
[`sinkSingle(receive:)`]: #sinksinglereceive
[Composing Single Publishers]: #composing-single-publishers
[Building Single Publishers]: #building-single-publishers
[Basic Single Publishers]: #basic-single-publishers
[TraitPublishers.Single]: TraitPublishers-Single.md
[TraitSubscriptions.Single]: #traitsubscriptionssingle
[Publisher]: https://developer.apple.com/documentation/combine/publisher
[Subscription]: https://developer.apple.com/documentation/combine/subscription
