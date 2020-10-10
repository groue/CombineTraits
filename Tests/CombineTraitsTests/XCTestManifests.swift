import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MaybePublisherTests.allTests),
        testCase(SinglePublisherTests.allTests),
        testCase(TraitPublishersMaybeTests.allTests),
        testCase(TraitPublishersSingleTests.allTests),
        testCase(TraitSubscriptionsMaybeTests.allTests),
        testCase(TraitSubscriptionsSingleTests.allTests),
    ]
}
#endif
