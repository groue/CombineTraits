TraitSubscriptions.Maybe
========================

**`TraitSubscriptions.Maybe` is a ready-made Combine [Subscription] that helps you building [maybe] publishers that wrap complex asynchronous apis.**

```swift
open class Maybe<Downstream: Subscriber, Context>: NSObject, Subscription {
    /// Creates a `Maybe` subscription
    init(downstream: Downstream, context: Context)
    
    /// Subclasses must override and eventually call the `receive` function
    open func start(with context: Context)
    
    /// Subclasses can override and perform eventual cleanup after the
    /// subscription was cancelled.
    ///
    /// The default implementation does nothing.
    open func didCancel(with context: Context)
    
    /// Subclasses can override and perform eventual cleanup after the
    /// subscription was completed.
    ///
    /// The default implementation does nothing.
    open func didComplete(with context: Context)
    
    /// Completes the subscription with the publisher result.
    func receive(_ result: MaybeResult<Downstream.Input, Downstream.Failure>)
}
```

---

`TraitSubscriptions.Maybe` is designed to be subclassed. Your custom subscriptions will override the `start(with:)` method in order to start their job, call the `receive(_:)` method in order to complete, and override `didCancel(with:)` when they should perform cancellation cleanup. Use `context` in order to pass any useful information.

For example, let's build a [maybe] publisher that lets a user pick a phone number from their address book. This publisher defines a subscription that subclasses `TraitSubscriptions.Maybe`:

```swift
import Combine
import CombineTraits
import ContactsUI
import UIKit

/// A publisher that presents the contact picker and lets the user pick
/// a phone number.
///
/// It publishes a phone number, or nothing if the user dismisses the contact
/// picker without making any choice.
///
/// It must be subscribed from the main thread.
struct PhoneNumberPublisher: MaybePublisher {
    typealias Output = CNPhoneNumber
    typealias Failure = Never
    
    let viewController: UIViewController
    
    init(presentingContactPickerFrom viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(
            downstream: subscriber,
            context: viewController)
        subscriber.receive(subscription: subscription)
    }
    
    private class Subscription<Downstream: Subscriber>:
        TraitSubscriptions.Maybe<Downstream, UIViewController>,
        CNContactPickerDelegate
    where
        Downstream.Input == Output,
        Downstream.Failure == Failure
    {
        override func start(with viewController: UIViewController) {
            let contactPicker = CNContactPickerViewController()
            contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            contactPicker.delegate = self
            viewController.present(contactPicker, animated: true, completion: nil)
        }
        
        override func didCancel(with viewController: UIViewController) {
            viewController.dismiss(animated: true)
        }
        
        // CNContactPickerDelegate
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            receive(.finished)
        }
        
        // CNContactPickerDelegate
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if let phoneNumber = contactProperty.value as? CNPhoneNumber {
                receive(.success(phoneNumber))
            }
        }
    }
}

// Usage:

class MyViewController: UIViewController {
    @IBAction func pickPhoneNumber() {
        PhoneNumberPublisher(presentingContactPickerFrom: self)
            .sinkMaybe { result in
                // handle result
            }
            .store(in: &cancellables)
    }
}
```

[maybe]: MaybePublisher.md
[Subscription]: https://developer.apple.com/documentation/combine/subscription
