import CancelBag
import Combine
import CombineTraits
import XCTest

class SinglePublisherTests: XCTestCase {
    func test_sinkSingle() {
        func test<P: SinglePublisher>(publisher: P, synchronouslyCompletesWithResult expectedResult: Result<P.Output, P.Failure>)
        where P.Output: Equatable, P.Failure: Equatable
        {
            let cancellables = CancelBag()
            var result: Result<P.Output, P.Failure>?
            _ = publisher.sinkSingle(in: cancellables, receive: { result = $0 })
            XCTAssertEqual(result, expectedResult)
        }
        
        struct TestError: Error, Equatable { }
        
        test(
            publisher: Just(1),
            synchronouslyCompletesWithResult: .success(1))
        
        test(
            publisher: Fail(outputType: Int.self, failure: TestError()),
            synchronouslyCompletesWithResult: .failure(TestError()))
    }
}
