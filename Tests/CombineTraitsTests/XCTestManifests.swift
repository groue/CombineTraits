import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MaybePublisherTests.allTests),
        testCase(MaybeSubscriptionTests.allTests),
        testCase(PublisherTraitsMaybeTests.allTests),
        testCase(PublisherTraitsSingleTests.allTests),
        testCase(SinglePublisherTests.allTests),
        testCase(SingleSubscriptionTests.allTests),
    ]
}
#endif
