import Combine

extension TraitPublishers {
    /// `ZipSingle` is a publisher that zips several single publishers together
    /// and publishes an array that contains as many elements as the
    /// zipped collection.
    ///
    /// It exists as a complement to `Publishers.Zip`, `Zip3` and `Zip4` that
    /// supports any number of publishers.
    ///
    /// When the collection is empty, `ZipSingle` publishes an empty array.
    public struct ZipSingle<Upstream>: SinglePublisher
    where Upstream: Collection,
          Upstream.Element: Publisher
    {
        public typealias Output = [Upstream.Element.Output]
        public typealias Failure = Upstream.Element.Failure
        
        fileprivate let collection: Upstream
        
        public func receive<S>(subscriber: S)
        where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
        {
            collection
                .reduce(into: Just([]).setFailureType(to: Failure.self).eraseToAnyPublisher()) { zipped, publisher in
                    zipped = zipped.zip(publisher) { $0 + [$1] }.eraseToAnyPublisher()
                }
                .receive(subscriber: subscriber)
        }
    }
}

extension Collection where Element: SinglePublisher {
    /// Returns a publisher that zips all publishers together and publishes
    /// an array that contains as many elements as the zipped collection.
    ///
    /// This method is a complement to `Publishers.Zip`, `Zip3` and `Zip4` that
    /// supports any number of publishers.
    ///
    /// When the collection is empty, the zipped publisher publishes an
    /// empty array.
    public func zipSingle() -> TraitPublishers.ZipSingle<Self> {
        TraitPublishers.ZipSingle(collection: self)
    }
}
