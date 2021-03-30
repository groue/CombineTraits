MaybePublisher
==============

**`MaybePublisher` is the protocol for publishers that publish exactly zero value, or one value, or an error.**

```swift
/// --------> can never publish anything, never complete.
/// -----x--> can fail before publishing any value.
/// -----|--> can complete without publishing any value.
/// --o--|--> can publish one value and complete.
protocol MaybePublisher: Publisher { }
```

When you import CombineTraits, many Combine publishers are extended with conformance to this protocol, such as `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher`. Other publishers are conditionally extended, such as `Publishers.Map` or `Publishers.FlatMap`.

Conversely, some publishers such as `Publishers.Sequence` are not extended with `MaybePublisher`, because not all sequences contain zero or one value.

- [AnyMaybePublisher]: a replacement for `AnyPublisher`
- [`sinkMaybe(receive:)`]: easy consumption of maybe publishers
- [Building Maybe Publishers]

## AnyMaybePublisher

`AnyMaybePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it certainly publishes exactly zero or one `String`, no more, no less:
    
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

Don't miss [Basic Maybe Publishers] for some handy shortcuts. The above publisher can be written as:

```swift
func namePublisher() -> AnyMaybePublisher<String, Error> {
    .just("Alice")
}
```

## `sinkMaybe(receive:)`

The `sinkMaybe(receive:)` method simplifies handling of maybe publisher results:
    
```swift
// 👍 There are only three cases to handle
let cancellable = namePublisher().sinkMaybe { (result: MaybeResult<String, Error>) in
    switch result {
    case .finished:
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

## Building Maybe Publishers

In order to benefit from the `MaybePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a maybe publisher:

- **Compiler-checked maybe publishers** are publishers that conform to the `MaybePublisher` protocol. This is the case of `Empty`, `Just` and `Fail`, for example. Some publishers conditionally conform to `MaybePublisher`, such as `Publishers.Map`, when the upstream publisher is a maybe publisher.
    
    When you define a publisher type that publishes exactly zero value, or one value, or an error, you can turn it into a maybe publisher with an extension:
    
    ```swift
    struct MyMaybePublisher: Publisher { ... }
    extension MyMaybePublisher: MaybePublisher { }
    
    let maybePublisher = MyMaybePublisher().eraseToAnyMaybePublisher()
    let cancellable = MyMaybePublisher().sinkMaybe { result in ... }
    ```

- **Runtime-checked maybe publishers** are publishers that conform to the `MaybePublisher` protocol by checking, at runtime, that an upstream publisher publishes exactly zero value, or one value, or an error.
    
    `Publisher.assertMaybe()` returns a maybe publisher that raises a fatal error if the upstream publisher does not honor the contract.
        
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

See also [Basic Maybe Publishers], [TraitPublishers.Maybe] and [TraitSubscriptions.Maybe].

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

[AnyMaybePublisher]: #anymaybepublisher
[`sinkMaybe(receive:)`]: #sinkmaybereceive
[Building Maybe Publishers]: #building-maybe-publishers
[Basic Maybe Publishers]: #basic-maybe-publishers
[TraitPublishers.Maybe]: TraitPublishers-Maybe.md
[TraitSubscriptions.Maybe]: TraitSubscriptions-Maybe.md
[Publisher]: https://developer.apple.com/documentation/combine/publisher
[Subscription]: https://developer.apple.com/documentation/combine/subscription
