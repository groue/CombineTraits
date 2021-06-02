Trait Operators
===============

#### `asOperation(in:queuePriority:)`

This operator builds a publisher that wraps the upstream [single] publisher in a Foundation Operation:

```swift
let operationQueue = OperationQueue()
let upstreamPublisher = ... // some single publisher
let publisher = upstreamPublisher.asOperation(in: operationQueue)
let publisher = upstreamPublisher.asOperation(in: operationQueue, queuePriority: .normal)
```

See [TraitPublishers.AsOperation].

#### `assertSingle()`, `assertMaybe()`, `assertImmediate()`

Use these operators for internal sanity checks, when you want to make sure that a publisher follows the rules of the [single], [maybe], or [immediate] trait.

The returned publisher raises a fatal error, in both development/testing and shipping versions of code, whenever the upstream publisher fails to follow the rules.

For example:

```swift
/// Publishes exactly one name
func namePublisher() -> AnySinglePublisher<String, Error> {
    nameSubject
        .prefix(1)
        .assertSingle()
        .eraseToAnySinglePublisher()
}
```

See [SinglePublisher], [MaybePublisher], [ImmediatePublisher].

#### `eraseToAnySinglePublisher()`, `eraseToAnyMaybePublisher()`, `eraseToAnyImmediatePublisher()`

Use these operators instead of `eraseToAnyPublisher()` when you want to expose a [single], [maybe], or [immediate] guarantee.

For example:

```swift
/// Publishes exactly one name
func namePublisher() -> AnySinglePublisher<String, Error> {
    /* some single publisher */.eraseToAnySinglePublisher()
}

/// Maybe publishes a name
func namePublisher() -> AnyMaybePublisher<String, Error> {O
    /* some maybe publisher */.eraseToAnyMaybePublisher()
}
```

See [SinglePublisher], [MaybePublisher], [ImmediatePublisher].

#### `fireAndForget()`, `fireAndForgetIgnoringFailure()`

Those methods subscribe to a [maybe] or [single] publisher, and let it proceed to completion, but do not report eventual element or completion.

```swift
myNetworkPublisher().fireAndForgetIgnoringFailure()
```

See [TraitPublishers.PreventCancellation].

#### `makeOperation()`

This operator creates a Foundation [Operation] that wraps an upstream publisher.

The publisher is subscribed when the operation starts, and the operation completes when the uptream publisher completes.

```swift
let publisher = ... // some single publisher
let operation = publisher.makeOperation()
let queue = OperationQueue()
queue.addOperation(operation)
```

See [SinglePublisherOperation].

#### `preventCancellation()`

This operator on a [single] or [maybe] publisher makes sure it proceeds to completion, even if a subscription is cancelled and its output is eventually ignored.

```swift
let upstreamPublisher = ... // some maybe or single publisher
let publisher = upstreamPublisher.preventCancellation()
```

See [TraitPublishers.PreventCancellation].

#### `replaceEmpty(withError:)`

Use this operator in order to turn a [maybe] publisher into a [single] publisher that fails when the upstream maybe is empty.

```swift
/// Maybe publishes a name
func nameMaybePublisher() -> AnyMaybePublisher<String, Never> { ... }

/// Publishes exactly one name, or an error
func nameSinglePublisher() -> AnySinglePublisher<String, Error> {
    nameMaybePublisher()
        .setFailureType(to: Error.self)
        .replaceEmpty(withError: MissingNameError())
}
```

See [SinglePublisher], [MaybePublisher].

#### `uncheckedSingle()`, `uncheckedMaybe()`, `uncheckedImmediate()`

Use these operators when you are sure that a publisher follows the rules of the [single], [maybe], or [immediate] trait.

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

The consequences of using those operators on a publisher that does not follow the rules are undefined.

See [SinglePublisher], [MaybePublisher], [ImmediatePublisher].

#### `zipSingle()`

This operator builds a [single] publisher out of a collection of [single] publishers:

```swift
let collection = [
    Just(1),
    Just(2),
]
let publisher = collection.zipSingle()
```

See [TraitPublishers.ZipSingle].


[single]: SinglePublisher.md
[maybe]: MaybePublisher.md
[immediate]: ImmediatePublisher.md
[SinglePublisher]: SinglePublisher.md
[MaybePublisher]: MaybePublisher.md
[ImmediatePublisher]: ImmediatePublisher.md
[Operation]: https://developer.apple.com/documentation/foundation/operation
[TraitPublishers.AsOperation]: TraitPublishers-AsOperation.md
[TraitPublishers.PreventCancellation]: TraitPublishers-PreventCancellation.md
[TraitPublishers.ZipSingle]: TraitPublishers-ZipSingle.md
[SinglePublisherOperation]: SinglePublisherOperation.md
