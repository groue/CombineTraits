TraitPublishers.AsOperation
===========================

**`TraitPublishers.AsOperation` is a publisher that wraps the upstream [single] publisher in a Foundation Operation.**

```swift
struct AsOperation<Upstream: SinglePublisher>: SinglePublisher {
    let upstream: Upstream
    let operationQueue: OperationQueue
    
    /// Creates an `AsOperation` publisher
    init(upstream: Upstream, operationQueue: OperationQueue)
}
```

---

**Usage**:

```swift
let operationQueue = OperationQueue()
let upstreamPublisher = ... // some single publisher
let publisher = upstreamPublisher.asOperation(in: operationQueue)
```

When it is subscribed, the publisher creates and schedules a new Operation in the OperationQueue. The subscription completes with the operation, when the uptream publisher completes.

Use `subscribe(on:options:)` when you need to control when the upstream publisher is subscribed:

```swift
let publisher = upstreamPublisher
    .subscribe(on: DispatchQueue.main)
    .asOperation(in: queue)
```

Use `receive(on:options:)` when you need to control when the returned publisher publishes its element and completion:

```swift
let publisher = upstreamPublisher
    .asOperation(in: queue)
    .receive(on: DispatchQueue.main)
```

When the operation queue has a `maxConcurrentOperationCount` of 1, `TraitPublishers.AsOperation` makes it possible to serialize publishers subscriptions.

See also [SinglePublisherOperation].

[SinglePublisherOperation]: SinglePublisherOperation.md
[single]: SinglePublisher.md
