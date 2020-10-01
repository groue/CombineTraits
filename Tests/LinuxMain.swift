import XCTest

import CombineTraitsTests

var tests = [XCTestCaseEntry]()
tests += MaybePublisherTests.allTests()
tests += MaybeSubscriptionTests.allTests()
tests += PublisherTraitsMaybeTests.allTests()
tests += PublisherTraitsSingleTests.allTests()
tests += SinglePublisherTests.allTests()
tests += SingleSubscriptionTests.allTests()
XCTMain(tests)
