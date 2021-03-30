SinglePublisherOperation
========================

**`SinglePublisherOperation` is a subclass of Foundation's [Operation] that subscribes to a [single] publisher and reports its result.**

```swift
open class AsynchronousOperation<Output, Failure: Error>: Operation { }
class SinglePublisherOperation<Upstream: SinglePublisher>: AsynchronousOperation<Upstream.Output, Upstream.Failure> { }
```

---

The publisher is subscribed when the operation starts, and the operation completes when the uptream publisher completes:

```swift
let publisher = ... // some single publisher
let operation = publisher.makeOperation()
let queue = OperationQueue()
queue.addOperation(operation)
```

To grab the result of the publisher from the operation, query the operation's result, of type `Result<Output, Failure>`:

```swift
if let result = operation.result {
    // Operation is finished
} else {
    // Operation is not finished, or cancelled
}
```

See also [TraitPublishers.AsOperation].

[single]: SinglePublisher.md
[TraitPublishers.AsOperation]: TraitPublishers-AsOperation.md
[Operation]: https://developer.apple.com/documentation/foundation/operation
