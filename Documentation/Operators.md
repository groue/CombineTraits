Trait Operators
===============

#### `assertSingle()`, `assertMaybe()`

Use these operators for internal sanity checks, when you want to make sure that a publisher follows the rules of the [single] or [maybe] trait.

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

#### `eraseToAnySinglePublisher()`, `eraseToAnyMaybePublisher()`

Use these operators instead of `eraseToAnyPublisher()` when you want to expose a [single] or [maybe] guarantee.

For example:

```swift
/// Publishes exactly one name
func namePublisher() -> AnySinglePublisher<String, Error> {
    /* some single publisher */.eraseToAnySinglePublisher()
}

/// Maybe publishes a name
func namePublisher() -> AnyMaybePublisher<String, Error>
    /* some maybe publisher */.eraseToAnyMaybePublisher()
}
```

#### `uncheckedSingle()`, `uncheckedMaybe()`

Use these operators when you are sure that a publisher follows the rules of the [single] or [maybe] trait.

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
