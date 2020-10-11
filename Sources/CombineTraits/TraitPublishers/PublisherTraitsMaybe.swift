import Combine

extension TraitPublishers {
    /// `TraitPublishers.Maybe` is a ready-made Combine [Publisher] which allows
    /// you to dynamically send success or failure events.
    ///
    /// It lets you easily create custom maybe publishers to wrap most
    /// non-publisher asynchronous work.
    ///
    /// You create this publisher by providing a closure. This closure runs when
    /// the publisher is subscribed to. It returns a cancellable object in which
    /// you define any cleanup actions to execute when the publisher completes,
    /// or when the subscription is canceled.
    ///
    ///     let publisher = TraitPublishers.Maybe<String, MyError> { promise in
    ///         // Eventually send completion event, now or in the future:
    ///         promise(.empty)
    ///         // OR
    ///         promise(.success("Alice"))
    ///         // OR
    ///         promise(.failure(MyError()))
    ///
    ///         return AnyCancellable {
    ///             // Perform cleanup
    ///         }
    ///     }
    ///
    /// `TraitPublishers.Maybe` is a "deferred" maybe publisher:
    ///
    /// - Nothing happens until the publisher is subscribed to. A new job starts
    ///   on each subscription.
    /// - It can complete right on subscription, or at any time in the future.
    ///
    /// When needed, `TraitPublishers.Maybe` can forward its job to another
    /// maybe publisher:
    ///
    ///     let publisher = TraitPublishers.Maybe<String, MyError> { promise in
    ///         return otherMaybePublisher.sinkMaybe(receive: promise)
    ///     }
    public struct Maybe<Output, Failure: Error>: MaybePublisher {
        public typealias Promise = (MaybeResult<Output, Failure>) -> Void
        typealias Start = (@escaping Promise) -> AnyCancellable
        let start: Start
        
        // TODO: doc
        // TODO: allow any cancellable
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
            TraitSubscriptions.Maybe<Downstream, Start>
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
