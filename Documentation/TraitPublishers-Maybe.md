TraitPublishers.Maybe
=====================

**`TraitPublishers.Maybe` is a ready-made [maybe] Combine [Publisher] which allows you to dynamically send success or failure events.**

```swift
struct Maybe<Output, Failure: Error>: MaybePublisher {
    typealias Promise = (MaybeResult<Output, Failure>) -> Void
    
    /// Creates a `Maybe` publisher
    init(_ start: @escaping (@escaping Promise) -> AnyCancellable)
}
```

---

`TraitPublishers.Maybe` lets you easily create custom maybe publishers to wrap most non-publisher asynchronous work.

You create this publisher by providing a closure. This closure runs when the publisher is subscribed to. It returns a cancellable object in which you define any cleanup actions to execute when the publisher completes, or when the subscription is canceled.

```swift
let publisher = TraitPublishers.Maybe<String, MyError> { promise in
    // Eventually send completion event, now or in the future:
    promise(.finished)
    // OR
    promise(.success("Alice"))
    // OR
    promise(.failure(MyError()))
    
    return AnyCancellable { 
        // Perform cleanup
    }
}
```

`TraitPublishers.Maybe` is a "deferred" maybe publisher:

- Nothing happens until the publisher is subscribed to. A new job starts on each subscription.
- It can complete right on subscription, or at any time in the future.

When needed, `TraitPublishers.Maybe` can forward its job to another maybe publisher:

```swift
let publisher = TraitPublishers.Maybe<String, MyError> { promise in
    return otherMaybePublisher.sinkMaybe(receive: promise)
}
```

[maybe]: MaybePublisher.md
[Publisher]: https://developer.apple.com/documentation/combine/publisher
