import XCTest

import CombineTraitsTests

var tests = [XCTestCaseEntry]()
tests += MaybeSubscriptionTests.allTests(),
tests += SinglePublisherTests.allTests()
XCTMain(tests)
