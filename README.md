CombineTraits [![Swift 5.3](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/) [![License](https://img.shields.io/github/license/groue/CombineTraits.svg?maxAge=2592000)](/LICENSE)
=============

### Guarantees on the number of values published by Combine publishers

**Requirements**: iOS 13.0+ / OSX 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.3+ / Xcode 12.0+

---

## What is this?

One must generally assume that [Combine] publishers may publish zero, one, or more values before they complete. It is particularly the case of [AnyPublisher], frequently returned by our frameworks or applications.

When we deal with publishers that are expected to publish no more than one value, such as network requests for example, we often neglect to deal with edge cases such as a completion without any value, or several published values.

The trouble is that the guarantees about the number of published vales are implicit, subject to interpretation, misunderstandings, wrong documentation, and buggy implementations.

**The compiler does not help us writing code that is guaranteed to be correct.**

This library provides both safe *subscription* and *construction* of publishers that explicitly conform to specific traits:
        
- **[Single Publishers]** are guaranteed to publish exactly one value, or an error.
    
    The Combine `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> A single publisher can never publish anything.
    -----x--> A single publisher can fail before publishing any value.
    --o--|--> A single publisher can publish one value and complete.
    ```
    
- **[Maybe Publishers]** are guaranteed to publish exactly zero value, or one value, or an error:
    
    The Combine `Empty`, `Just`, `Future` and `URLSession.DataTaskPublisher` are examples of such publishers.
    
    ```
    --------> A maybe publisher can never publish anything.
    -----x--> A maybe publisher can fail before publishing any value.
    -----|--> A maybe publisher can complete without publishing any value.
    --o--|--> A maybe publisher can publish one value and complete.
    ```

# Documentation

- [Usage]
- [Single Publishers]
- [Maybe Publishers]
- [Trait Operators]

## Usage

**CombineTraits carefully preserves the general ergonomics of Combine.** Your application still deals with regular Combine publishers and operators.

`AnyPublisher` can be replaced with `AnySinglePublisher` or `AnyMaybePublisher`, in order to express which trait a publisher conforms to:
    
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
[Single Publishers]: Documentation/Single.md
[Maybe Publishers]: Documentation/Maybe.md
[Trait Operators]: Documentation/Operators.md
