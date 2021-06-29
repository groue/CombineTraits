import Combine

extension TraitPublishers {
    /// `ZipSingle` is a publisher that zips several single publishers together
    /// and publishes one array of all published elements.
    ///
    /// It exists as a complement to `Publishers.Zip`, `Zip3` and `Zip4` that
    /// supports any number of publishers.
    ///
    /// When the collection is empty, `ZipSingle` publishes an empty array.
    public struct ZipSingle<UpstreamCollection>: SinglePublisher
    where UpstreamCollection: Collection,
          UpstreamCollection.Element: Publisher
    {
        public typealias Output = [UpstreamCollection.Element.Output]
        public typealias Failure = UpstreamCollection.Element.Failure
        
        /// The zipped collection
        public let collection: UpstreamCollection
        
        /// Creates a `ZipSingle` publisher
        public init(collection: UpstreamCollection) {
            self.collection = collection
        }
        
        public func receive<S>(subscriber: S)
        where S: Subscriber, Failure == S.Failure, Output == S.Input
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
    /// one array of all published elements.
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
