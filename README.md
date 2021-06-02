CombineTraits [![Swift 5.3](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/)
=============

### Combine Publishers with Guarantees

**Requirements**: iOS 13.0+ / OSX 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.3+ / Xcode 12.0+

---

## What is this?

[Combine] publishers can publish any number of values, at any time, before they complete. It is particularly the case of [AnyPublisher], frequently returned by our frameworks or applications.

When we deal with publishers that are expected to publish their values according to a specific pattern, it is easy to neglect edge cases such as late publishing, early completion, too many published values, etc. And quite often, the behavior of such publishers is subject to interpretation, imprecise documentation, or buggy implementations.

This library provides compiler-checked definition, and subscription, to publishers that conform to specific *traits*:
        
- **[Single Publishers]** publish exactly one value, or an error.
    
    The Combine `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> can never publish anything, never complete.
    -----x--> can fail before publishing any value.
    --o--|--> can publish one value and complete.
    ```
    
- **[Maybe Publishers]** publish exactly zero value, or one value, or an error:
    
    The Combine `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> can never publish anything, never complete.
    -----x--> can fail before publishing any value.
    -----|--> can complete without publishing any value.
    --o--|--> can publish one value and complete.
    ```
    
- **[Immediate Publishers]** publish a value or fail, right on subscription:
    
    The Combine `Just` and `Fail` are examples of such publishers.
    
    ```
    x-------> can fail immediately.
    o - - - > can publish one value immediately (and then publish any number
              of values, at any time, until the eventual completion).
    ```

# Documentation

- [Usage]
- [Single Publishers]
- [Maybe Publishers]
- [Immediate Publishers]

**Derived Tools**

- [Trait Operators]
- [SinglePublisherOperation]
- [TraitPublishers.AsOperation]
- [TraitPublishers.Maybe]
- [TraitPublishers.PreventCancellation]
- [TraitPublishers.Single]
- [TraitPublishers.ZipSingle]
- [TraitSubscriptions.Maybe]
- [TraitSubscriptions.Single]

## Usage

**CombineTraits preserves the general ergonomics of Combine.** Your application still deals with regular Combine publishers and operators.

`AnyPublisher` can be replaced with `AnySinglePublisher`, `AnyMaybePublisher`, or `AnyImmediatePublisher`, in order to express which trait a publisher conforms to:
    
```swift
func refreshPublisher() -> AnySinglePublisher<Void, Error> {
    downloadPublisher()
        .map { apiModel in Model(apiModel) }
        .flatMap { model in savePublisher(model) }
        .eraseToAnySinglePublisher()
}
```

On the consumption side, `sink` can be replaced with `sinkSingle` or `sinkMaybe`, for easier handling of a given publisher trait:
    
```swift
let cancellable = refreshPublisher().sinkSingle { result in
    switch result {
    case .success: ...
    case let .failure(error): ...
    }
}
```

[AnyPublisher]: https://developer.apple.com/documentation/combine/anypublisher
[Combine]: https://developer.apple.com/documentation/combine
[Release Notes]: CHANGELOG.md
[Usage]: #usage
[Single Publishers]: Documentation/SinglePublisher.md
[Maybe Publishers]: Documentation/MaybePublisher.md
[Immediate Publishers]: Documentation/ImmediatePublisher.md
[Trait Operators]: Documentation/Operators.md
[SinglePublisherOperation]: Documentation/SinglePublisherOperation.md
[TraitPublishers.AsOperation]: Documentation/TraitPublishers-AsOperation.md
[TraitPublishers.Maybe]: Documentation/TraitPublishers-Maybe.md
[TraitPublishers.PreventCancellation]: Documentation/TraitPublishers-PreventCancellation.md
[TraitPublishers.Single]: Documentation/TraitPublishers-Single.md
[TraitPublishers.ZipSingle]: Documentation/TraitPublishers-ZipSingle.md
[TraitSubscriptions.Maybe]: Documentation/TraitSubscriptions-Maybe.md
[TraitSubscriptions.Single]: Documentation/TraitSubscriptions-Single.md
