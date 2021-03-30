TraitPublishers.Single
======================

**`TraitPublishers.Single` is a ready-made [single] Combine [Publisher] which allows you to dynamically send success or failure events.**

```swift
struct Single<Output, Failure: Error>: SinglePublisher {
    typealias Promise = (Result<Output, Failure>) -> Void
    
    /// Creates a `Single` publisher
    init(_ start: @escaping (@escaping Promise) -> AnyCancellable)
}
```

---

`TraitPublishers.Single` lets you easily create custom single publishers to wrap most non-publisher asynchronous work.

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

[single]: SinglePublisher.md
[Publisher]: https://developer.apple.com/documentation/combine/publisher
