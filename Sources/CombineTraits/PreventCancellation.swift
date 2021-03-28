import Combine

extension TraitPublishers {
    /// `PreventCancellation` is a publisher that outputs the same element and
    /// completion as its upstream publisher.
    ///
    /// When a subscription to `PreventCancellation` is cancelled, the uptream
    /// subscription still proceeds to completion.
    public struct PreventCancellation<Upstream: MaybePublisher>: MaybePublisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        let upstream: Upstream
        
        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            TraitPublishers.Maybe { promise in
                var cancellable: AnyCancellable? = nil
                cancellable = upstream.sinkMaybe(receive: { result in
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
    /// Returns a publisher that outputs the same element and completion as the
    /// receiver publisher.
    ///
    /// When a subscription to the returned publisher is cancelled, the receiver
    /// still proceeds to completion.
    public func preventCancellation() -> TraitPublishers.PreventCancellation<Self> {
        TraitPublishers.PreventCancellation(upstream: self)
    }
}

extension MaybePublisher where Output == Void {
    /// Subscribes to the publisher and let it proceed to completion.
    public func fireAndForgetIgnoringFailure() {
        _ = preventCancellation().sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

extension MaybePublisher where Output == Void, Failure == Never {
    /// Subscribes to the publisher and let it proceed to completion.
    public func fireAndForget() {
        _ = preventCancellation().sink(receiveValue: { _ in })
    }
}
