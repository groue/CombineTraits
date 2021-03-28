Trait Operators
===============

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

#### `preventCancellation()`

This operator on a [single] or [maybe] publisher makes sure it proceeds to completion, even if a subscription is cancelled and its output is eventually ignored.

Use this operator in order to guarantee that the consequences of some intent are fully applied. For example:

```swift
func signOutPublisher() -> AnySinglePublisher<Void, Never> {
    Publishers
        .Zip3(
            invalidateSessionsPublisher(),
            eraseLocalDataPublisher(),
            unregisterFromRemoteNotificationsPublisher())
        .map { _ in }
        // Make sure sign out proceeds to completion
        .preventCancellation()
        .eraseToAnySinglePublishers()
}
```

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

[single]: Single.md
[maybe]: Maybe.md
[immediate]: Immediate.md
