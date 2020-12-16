Immediate Publishers
====================

**`ImmediatePublisher` is the protocol for publishers that publish a value or fail, right on subscription.**

```swift
/// x-------> can fail immediately.
/// o - - - > can publish one value immediately (and then publish any number
///           of values, at any time, until the eventual completion).
protocol ImmediatePublisher: Publisher { }
```

When you import CombineTraits, many Combine publishers are extended with conformance to `ImmediatePublisher`, such as `Just`, `Fail` and `CurrentValueSubject`. Other publishers are conditionally extended, such as `Publishers.Map` or `Publishers.FlatMap`.

Conversely, some publishers such as `Publishers.Sequence` are not extended with `ImmediatePublisher`, because not all sequences contain a value.

- [AnyImmediatePublisher]: a replacement for `AnyPublisher`
- [Building Immediate Publishers]

## AnyImmediatePublisher

`AnyImmediatePublisher` is a publisher type that hides details you don’t want to expose across API boundaries. For example, the user of the publisher below knows that it publishes exactly one `String`, no more, no less:
    
```swift
/// 👍 Publishes one name right on subscription
func namePublisher() -> AnyImmediatePublisher<String, Never>
```

Compare with the regular `AnyPublisher`, where documentation is the only way to express the "immediate" guarantee:

```swift
/// 😥 Trust us: this publisher publishes one name right on subscription.
func namePublisher() -> AnyPublisher<String, Never>
```

You build an `AnyImmediatePublisher` with the `ImmediatePublisher.eraseToAnyImmediatePublisher()` method. For example:

```swift
func namePublisher() -> AnyImmediatePublisher<String, Never> {
    Just("Alice").eraseToAnyImmediatePublisher()
}
```

Don't miss [Basic Immediate Publishers] for some handy shortcuts. The above publisher can be written as:

```swift
func namePublisher() -> AnyImmediatePublisher<String, Never> {
    .just("Alice")
}
```

## Building Immediate Publishers

In order to benefit from the `ImmediatePublisher` protocol, you need a concrete publisher that conforms to this protocol.

There are a few ways to get such a immediate publisher:

- **Compiler-checked immediate publishers** are publishers that conform to the `ImmediatePublisher` protocol. This is the case of `Just` and `Fail`, for example. Some publishers conditionally conform to `ImmediatePublisher`, such as `Publishers.Map`, when the upstream publisher is a immediate publisher.
    
    When you define a publisher type that publishes a value or fails, right on subscription, you can turn it into a immediate publisher with an extension:
    
    ```swift
    struct MyImmediatePublisher: Publisher { ... }
    extension MyImmediatePublisher: ImmediatePublisher { }
    
    let immediatePublisher = MyImmediatePublisher().eraseToAnyImmediatePublisher()
    let cancellable = MyImmediatePublisher().sinkImmediate { result in ... }
    ```

- **Runtime-checked immediate publishers** are publishers that conform to the `ImmediatePublisher` protocol by checking, at runtime, that an upstream publisher publishes a value or fails, right on subscription.
    
    `Publisher.assertImmediate()` returns a immediate publisher that raises a fatal error if the upstream publisher does not honor the contract.
        
    For example:
    
    ```swift
    let nameSubject: PassthroughSubject<String, Never> = ...
    
    func namePublisher() -> AnyImmediatePublisher<String, Never> {
        subject.prepend("Unknown").assertImmediate().eraseToAnyImmediatePublisher()
    }
    ```

- **Unchecked immediate publishers**: you should only build such a immediate publisher when you are sure that the `ImmediatePublisher` contract is honored by the upstream publisher.
    
    For example:
    
    ```swift
    // CORRECT: those publish a value or fail, right on subscription.
    [1].publisher.uncheckedImmediate()
    [1, 2].publisher.prefix(1).uncheckedImmediate()
    
    // WRONG: does not publish any value, does not fail.
    Empty().uncheckedImmediate()
    ```
    
    The consequences of using `uncheckedImmediate()` on a publisher that does not publish a value or fail, right on subscription, are undefined.

See also [Basic Immediate Publishers].

### Basic Immediate Publishers

`AnyImmediatePublisher` comes with factory methods that build basic immediate publishers:

```swift
// Publishes one value, and then completes.
AnyImmediatePublisher.just(value)

// Fails with the given error.
AnyImmediatePublisher.fail(error)
```

They are quite handy:

```swift
func namePublisher() -> AnyImmediatePublisher<String, Error> {
    .just("Alice")
}
```


[AnyImmediatePublisher]: #anyimmediatepublisher
[Building Immediate Publishers]: #building-immediate-publishers
[Basic Immediate Publishers]: #basic-immediate-publishers
[Publisher]: https://developer.apple.com/documentation/combine/publisher
