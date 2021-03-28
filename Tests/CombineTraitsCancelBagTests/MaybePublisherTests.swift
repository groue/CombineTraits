import Combine
import CombineTraits
import XCTest

class MaybePublisherTests: XCTestCase {
    func test_sinkMaybe() {
        func test<P: MaybePublisher>(publisher: P, synchronouslyCompletesWithResult expectedResult: MaybeResult<P.Output, P.Failure>)
        where P.Output: Equatable, P.Failure: Equatable
        {
            let cancellables = CancelBag()
            var result: MaybeResult<P.Output, P.Failure>?
            _ = publisher.sinkMaybe(in: cancellables, receive: { result = $0 })
            XCTAssertEqual(result, expectedResult)
        }
        
        struct TestError: Error, Equatable { }
        
        test(
            publisher: Just(1),
            synchronouslyCompletesWithResult: .success(1))
        
        test(
            publisher: Empty(outputType: Int.self, failureType: Never.self),
            synchronouslyCompletesWithResult: .finished)
        
        test(
            publisher: Fail(outputType: Int.self, failure: TestError()),
            synchronouslyCompletesWithResult: .failure(TestError()))
    }
}
