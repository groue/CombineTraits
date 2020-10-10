import Combine

extension TraitPublishers {
    // TODO: doc
    public struct Maybe<Output, Failure: Error>: MaybePublisher {
        public typealias Promise = (MaybeResult<Output, Failure>) -> Void
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