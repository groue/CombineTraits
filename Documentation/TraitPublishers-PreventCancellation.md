TraitPublishers.PreventCancellation
===================================

**`TraitPublishers.PreventCancellation` prevents its upstream [maybe] or [single] publisher from being cancelled.**

```swift
struct PreventCancellation<Upstream: MaybePublisher>: MaybePublisher {
    /// The upstream publisher
    let upstream: Upstream
    
    /// Creates a `PreventCancellation` publisher
    init(upstream: Upstream)
}
```

---

**Usage**

```swift
let upstreamPublisher = ... // some maybe or single publisher
let publisher = upstreamPublisher.preventCancellation()
```

This publisher produces the same element and completion as its upstream publisher. If it is cancelled, upstream proceeds to completion nevertheless (and its element and completion are left unhandled).

**fireAndForget()**

When you want to subscribe to a publisher, and let it proceed to completion without handling its output and completion, you can use the `fireAndForget` subscription method. `fireAndForget` is available on [maybe] publishers when `Output` is `Never`. You can use [`ignoreOutput()`] in order to get such a `Never` publisher:

```swift
publisher.ignoreOutput().fireAndForget() // Available if Failure is Never
publisher.ignoreOutput().fireAndForgetIgnoringFailure()
```

[maybe]: MaybePublisher.md
[single]: SinglePublisher.md
[`ignoreOutput()`]: https://developer.apple.com/documentation/combine/publisher/ignoreoutput()
