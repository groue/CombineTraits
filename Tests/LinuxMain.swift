import XCTest

import CombineTraitsTests

var tests = [XCTestCaseEntry]()
tests += MaybePublisherTests.allTests()
tests += SinglePublisherTests.allTests()
tests += TraitPublishersMaybeTests.allTests()
tests += TraitPublishersSingleTests.allTests()
tests += TraitSubscriptionsMaybeTests.allTests()
tests += TraitSubscriptionsSingleTests.allTests()
XCTMain(tests)
