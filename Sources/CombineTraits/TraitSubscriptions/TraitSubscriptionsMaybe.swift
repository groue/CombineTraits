import Combine
import Foundation

extension TraitSubscriptions {
    /// `TraitSubscriptions.Maybe` helps building maybe publishers.
    ///
    /// To implement a custom subscription, subclass `TraitSubscriptions.Maybe`,
    /// and override `start` and `didCancel`:
    ///
    ///     struct MyMaybePublisher: MaybePublisher {
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
    ///             TraitSubscriptions.Maybe<Downstream, MyContext>
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
    open class Maybe<Downstream: Subscriber, Context>: NSObject, Subscription {
        private enum State {
            case waitingForDemand(downstream: Downstream, context: Context)
            case waitingForFulfillment(downstream: Downstream, context: Context)
            case finished
        }
        
        private var state: State
        private let lock = NSRecursiveLock() // Allow re-entrancy
        
        public init(
            downstream: Downstream,
            context: Context)
        {
            self.state = .waitingForDemand(downstream: downstream, context: context)
        }
        
        public func request(_ demand: Subscribers.Demand) {
            synchronized {
                switch state {
                case let .waitingForDemand(downstream: downstream, context: context):
                    guard demand > 0 else {
                        return
                    }
                    state = .waitingForFulfillment(downstream: downstream, context: context)
                    start(with: context)
                    
                case .waitingForFulfillment, .finished:
                    break
                }
            }
        }
        
        /// Subclasses must override and eventually call the `receive` function
        open func start(with context: Context) { }
        
        /// Subclasses can override and perform eventual cleanup after the
        /// subscription was cancelled.
        open func didCancel(with context: Context) { }
        
        public func receive(_ result: MaybeResult<Downstream.Input, Downstream.Failure>) {
            synchronized {
                switch state {
                case let .waitingForFulfillment(downstream: downstream, context: _):
                    state = .finished
                    switch result {
                    case .empty:
                        downstream.receive(completion: .finished)
                    case let .success(value):
                        _ = downstream.receive(value)
                        downstream.receive(completion: .finished)
                    case let .failure(error):
                        downstream.receive(completion: .failure(error))
                    }
                    
                case .waitingForDemand, .finished:
                    break
                }
            }
        }
        
        public func cancel() {
            synchronized {
                switch state {
                case let .waitingForFulfillment(downstream: _, context: context):
                    state = .finished
                    didCancel(with: context)
                case .waitingForDemand, .finished:
                    state = .finished
                }
            }
        }
        
        private func synchronized<T>(_ block: () throws -> T) rethrows -> T {
            defer { lock.unlock() }
            lock.lock()
            return try block()
        }
    }
}
