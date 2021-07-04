import Combine

extension TraitPublishers {
    /// `PreventCancellation` prevents its upstream publisher from
    /// being cancelled.
    public struct PreventCancellation<Upstream: MaybePublisher>: MaybePublisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        /// The upstream publisher
        public let upstream: Upstream
        
        /// Creates a `PreventCancellation` publisher
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            TraitPublishers.Maybe { promise in
                var cancellable: AnyCancellable? = nil
                cancellable = self.upstream.sinkMaybe(receive: { result in
                    promise(result)
                    withExtendedLifetime(cancellable) {
                        cancellable = nil
                    }
                })
                return AnyCancellable { }
            }.receive(subscriber: subscriber)
        }
    }
}

extension TraitPublishers.PreventCancellation: SinglePublisher where Upstream: SinglePublisher { }

extension MaybePublisher {
    /// Returns a publisher that produces the same element and completion as the
    /// upstream publisher. If it is cancelled, upstream proceeds to completion
    /// nevertheless (and its element and completion are left unhandled).
    public func preventCancellation() -> TraitPublishers.PreventCancellation<Self> {
        TraitPublishers.PreventCancellation(upstream: self)
    }
}

extension MaybePublisher where Output == Never {
    /// Subscribes to the publisher and let it proceed to completion.
    public func fireAndForgetIgnoringFailure() {
        _ = preventCancellation().sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

extension MaybePublisher where Output == Never, Failure == Never {
    /// Subscribes to the publisher and let it proceed to completion.
    public func fireAndForget() {
        _ = preventCancellation().sink(receiveValue: { _ in })
    }
}
