import Combine
import Foundation

extension TraitSubscriptions {
    /// `TraitSubscriptions.Single` helps building single publishers.
    ///
    /// To implement a custom subscription, subclass `TraitSubscriptions.Single`,
    /// and override `start` and `didCancel`:
    ///
    ///     struct MySinglePublisher: SinglePublisher {
    ///         typealias Output = MyOutput
    ///         typealias Failure = MyFailure
    ///
    ///         let context: MyContext
    ///
    ///         func receive<S>(subscriber: S)
    ///         where S: Subscriber, Failure == S.Failure, Output == S.Input
    ///         {
    ///             let subscription = Subscription(
    ///                 downstream: subscriber,
    ///                 context: context)
    ///             subscriber.receive(subscription: subscription)
    ///         }
    ///
    ///         private class Subscription<Downstream: Subscriber>:
    ///             TraitSubscriptions.Single<Downstream, MyContext>
    ///         where
    ///             Downstream.Input == Output,
    ///             Downstream.Failure == Failure
    ///         {
    ///             override func start(with context: MyContext) {
    ///                 // Subscription was requested a value.
    ///                 // Eventually call `receive(_:)`
    ///                 receive(.success(...))
    ///             }
    ///
    ///             override func didCancel(with context: MyContext) {
    ///                 // Subscription was cancelled.
    ///             }
    ///         }
    ///     }
    open class Single<Downstream: Subscriber, Context>: NSObject, Subscription {
        private enum State {
            case waitingForDemand(downstream: Downstream, context: Context)
            case waitingForFulfillment(downstream: Downstream, context: Context)
            case finished
        }
        
        private var state: State
        private let lock = NSLock()
        
        public init(
            downstream: Downstream,
            context: Context)
        {
            self.state = .waitingForDemand(downstream: downstream, context: context)
        }
        
        public func request(_ demand: Subscribers.Demand) {
            lock.lock()
            switch state {
            case let .waitingForDemand(downstream: downstream, context: context):
                guard demand > 0 else {
                    lock.unlock()
                    return
                }
                state = .waitingForFulfillment(downstream: downstream, context: context)
                lock.unlock()
                start(with: context)
                
            case .waitingForFulfillment, .finished:
                lock.unlock()
            }
        }
        
        /// Subclasses must override and eventually call the `receive` function
        open func start(with context: Context) { }
        
        /// Subclasses can override and perform eventual cleanup after the
        /// subscription was cancelled.
        ///
        /// The default implementation does nothing.
        open func didCancel(with context: Context) { }
        
        /// Subclasses can override and perform eventual cleanup after the
        /// subscription was completed.
        ///
        /// The default implementation does nothing.
        open func didComplete(with context: Context) { }
        
        /// Completes the subscription with the publisher result.
        ///
        /// You can not override this method. Override
        /// `didComplete(with:)` instead.
        public func receive(_ result: Result<Downstream.Input, Downstream.Failure>) {
            lock.lock()
            switch state {
            case let .waitingForFulfillment(downstream: downstream, context: context):
                state = .finished
                lock.unlock()
                didComplete(with: context)
                
                switch result {
                case let .success(value):
                    _ = downstream.receive(value)
                    downstream.receive(completion: .finished)
                case let .failure(error):
                    downstream.receive(completion: .failure(error))
                }
                
            case .waitingForDemand, .finished:
                lock.unlock()
            }
        }
        
        public func cancel() {
            lock.lock()
            switch state {
            case let .waitingForFulfillment(downstream: _, context: context):
                state = .finished
                lock.unlock()
                didCancel(with: context)
            case .waitingForDemand, .finished:
                state = .finished
                lock.unlock()
            }
        }
    }
}
