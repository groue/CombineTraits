Release Notes
=============

All notable changes to this project will be documented in this file.

**2023-09-04**

- Swift 5.9+

**2021-06-02**

- Expose the `AsynchronousOperation` target.
- Add the `asOperation(in:queuePriority:)` operator.

**2021-03-29**

- Introduce `SinglePublisherOperation`
- Introduce `TraitPublishers.AsOperation`

**2021-03-28**

- [Operators](Documentation/Operators.md) Introduce `MaybePublisher.fireAndForget()` and `fireAndForgetIgnoringFailure()`
- [Operators](Documentation/Operators.md) Introduce `MaybePublisher.preventCancellation()`
- Introduce `CancelBag`
- Introduce `TraitPublishers.ZipSingle`

**2021-01-11**

- [Operators](Documentation/Operators.md) Introduce `SinglePublisher.preventCancellation()`

**2020-12-16**

- [Immediate](Documentation/ImmediatePublisher.md) Introduce `ImmediatePublisher`
