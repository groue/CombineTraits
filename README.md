CombineTraits [![Swift 5.3](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/) [![License](https://img.shields.io/github/license/groue/CombineTraits.svg?maxAge=2592000)](/LICENSE)
=============

### Guarantees on the number of elements published by Combine publishers

**Requirements**: iOS 13.0+ / OSX 10.15+ / tvOS 13.0+ / watchOS 6.0+ &bull; Swift 5.3+ / Xcode 12.0+

---

## What is this?

CombineTraits solves a problem with the [Combine] framework: publishers do not tell how many elements can be published. It is particularly the case of `[AnyPublisher]`, the publisher type that is the most frequently returned by our frameworks or applications: one must generally assume that it may publish zero, one, or more elements before it completes.

Quite often, we have to rely on the context or the documentation in order to lift doubts. For example, we expect a publisher that publishes the result of some network request to publish only one value, or the eventual network error. We do not deal with odd cases such as a completion without any value, or several published values.

And sometimes, we build a publisher that we *think* will publish a single value before completion. Unfortunately we write bugs and our publisher fails to honor its own contract. This can trigger bugs in other parts of our application.

**In both cases, the compiler did not help us writing code that is guaranteed to be correct.** That's what CombineTraits is about.

This library comes with support for two publisher traits:
        
- **Single** publishers are guaranteed to publish exactly one element, or an error:
    
        --------> A single publisher can never publish anything.
        -----x--> A single publisher can fail.
        --o--|--> A single publisher can publish one value and complete.
    
- **Maybe** publishers are guaranteed to publish exactly zero element, or one element, or an error:
    
        --------> A maybe publisher can never publish anything.
        -----x--> A maybe publisher can fail.
        -----|--> A maybe publisher can complete without publishing any value.
        --o--|--> A maybe publisher can publish one value and complete.

# Documentation

- [The SinglePublisher Protocol]
- [The MaybePublisher Protocol]
- [Tools]

## The SinglePublisher Protocol

- [SinglePublisher Benefits]
- [Building Single Publishers]
- [Basic Single Publishers]

### SinglePublisher Benefits
### Building Single Publishers
### Basic Single Publishers

## The MaybePublisher Protocol

- [MaybePublisher Benefits]
- [Building Maybe Publishers]
- [Basic Maybe Publishers]

### MaybePublisher Benefits
### Building Maybe Publishers
### Basic Maybe Publishers

## Tools

- [TraitPublishers.Single]
- [TraitPublishers.Maybe]
- [SingleSubscription]
- [MaybeSubscription]

### TraitPublishers.Single
### TraitPublishers.Maybe
### SingleSubscription
### MaybeSubscription


[AnyPublisher]: https://developer.apple.com/documentation/combine/anypublisher
[Combine]: https://developer.apple.com/documentation/combine
[Release Notes]: CHANGELOG.md
[The SinglePublisher Protocol]: #the-singlepublisher-protocol
[SinglePublisher Benefits]: #singlepublisher-benefits
[Building Single Publishers]: #building-single-publishers
[Basic Single Publishers]: #basic-single-publishers
[The MaybePublisher Protocol]: #the-maybepublisher-protocol
[MaybePublisher Benefits]: #maybepublisher-benefits
[Building Maybe Publishers]: #building-maybe-publishers
[Basic Maybe Publishers]: #basic-maybe-publishers
[Tools]: #Tools
[TraitPublishers.Single]: #traitpublisherssingle
[TraitPublishers.Maybe]: #traitpublishersmaybe
[SingleSubscription]: #singlesubscription
[MaybeSubscription]: #maybesubscription
