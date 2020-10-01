import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MaybeSubscriptionTests.allTests),
        testCase(SinglePublisherTests.allTests),
    ]
}
#endif
