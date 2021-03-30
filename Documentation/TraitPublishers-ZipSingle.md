TraitPublishers.ZipSingle
=========================

**`TraitPublishers.ZipSingle` is a [single] [Publisher] that zips several [single] publishers together and publishes one array of all published elements.**

```swift
struct ZipSingle<UpstreamCollection>: SinglePublisher
where UpstreamCollection: Collection,
      UpstreamCollection.Element: Publisher
{
    /// The zipped collection
    let collection: UpstreamCollection
    
    /// Creates a `ZipSingle` publisher
    init(collection: UpstreamCollection)
}
```

---

`TraitPublishers.ZipSingle` exists as a complement to the Combine `Publishers.Zip`, `Zip3` and `Zip4` that supports any number of publishers.

When the zipped collection is empty, `ZipSingle` publishes an empty array.

**Usage**

```swift
let collection = [
    Just(1),
    Just(2),
]
let publisher = collection.zipSingle()
_ = publisher.sink { values in
    print(values) // prints "[1, 2]"
}
```

[single]: SinglePublisher.md
[Publisher]: https://developer.apple.com/documentation/combine/publisher
