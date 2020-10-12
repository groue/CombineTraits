import Combine

extension TraitPublishers {
    /// `TraitPublishers.Single` is a ready-made Combine [Publisher] which which
    /// allows you to dynamically send success or failure events.
    ///
    /// It lets you easily create custom single publishers to wrap most
    /// non-publisher asynchronous work.
    ///
    /// You create this publisher by providing a closure. This closure runs when
    /// the publisher is subscribed to. It returns a cancellable object in which
    /// you define any cleanup actions to execute when the publisher completes,
    /// or when the subscription is canceled.
    ///
    ///     let publisher = TraitPublishers.Single<String, MyError> { promise in
    ///         // Eventually send completion event, now or in the future:
    ///         promise(.success("Alice"))
    ///         // OR
    ///         promise(.failure(MyError()))
    ///
    ///         return AnyCancellable {
    ///             // Perform cleanup
    ///         }
    ///     }
    ///
    /// `TraitPublishers.Single` can be seen as a "deferred future"
    /// single publisher:
    ///
    /// - Nothing happens until the publisher is subscribed to. A new job starts
    ///   on each subscription.
    /// - It can complete right on subscription, or at any time in the future.
    ///
    /// When needed, `TraitPublishers.Single` can forward its job to another
    /// single publisher:
    ///
    ///     let publisher = TraitPublishers.Single<String, MyError> { promise in
    ///         return otherSinglePublisher.sinkSingle(receive: promise)
    ///     }
    public struct Single<Output, Failure: Error>: SinglePublisher {
        public typealias Promise = (Result<Output, Failure>) -> Void
        typealias Start = (@escaping Promise) -> AnyCancellable
        let start: Start
        
        // TODO: doc
        public init(_ start: @escaping (@escaping Promise) -> AnyCancellable) {
            self.start = start
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(
                downstream: subscriber,
                context: start)
            subscriber.receive(subscription: subscription)
        }
        
        private class Subscription<Downstream: Subscriber>:
            TraitSubscriptions.Single<Downstream, Start>
        where
            Downstream.Input == Output,
            Downstream.Failure == Failure
        {
            var cancellable: AnyCancellable?
            
            override func start(with start: @escaping Start) {
                cancellable = start { result in
                    self.receive(result)
                }
            }
            
            override func didCancel(with start: @escaping Start) {
                cancellable?.cancel()
            }
        }
    }
}
