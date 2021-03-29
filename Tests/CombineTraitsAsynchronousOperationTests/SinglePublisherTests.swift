import Combine
import CombineExpectations
import CombineTraits
import Foundation
import XCTest

class SinglePublisherTests: XCTestCase {
    func test_makeOperation() {
        let publisher = Just(1)
        let operation = publisher.makeOperation()
        let expectation = self.expectation(description: "")
        operation.handleCompletion { result in
            guard let result = result,
                  case let .success(value) = result
            else {
                XCTFail("Missing result")
                return
            }
            XCTAssertEqual(value, 1)
            expectation.fulfill()
        }
        OperationQueue().addOperation(operation)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_makeOperation_cancelling_the_operation_cancels_the_subscription() {
        let expectation = self.expectation(description: "")
        var operation: Operation?
        let publisher = AnySinglePublisher<Never, Never>
            .never()
            .handleEvents(
                receiveSubscription: { _ in
                    // Combine doesn't trigger the `receiveCancel` callback when
                    // cancellation is performed from the `receiveSubscription`
                    // callback.
                    //
                    // So let's postpone the cancellation with a queue hop:
                    DispatchQueue.main.async {
                        operation?.cancel()
                    }
                },
                receiveCancel: {
                    expectation.fulfill()
                })
        operation = publisher.makeOperation()
        OperationQueue().addOperation(operation!)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_asOperation() throws {
        let queue = OperationQueue()
        queue.isSuspended = true
        let publisher = Just(1).asOperation(in: queue)
        let recorder = publisher.record()
        
        // Publisher does not publish if queue is suspended
        try wait(for: recorder.finished.inverted, timeout: 0.5)
        
        // Publisher does publish if queue is started
        queue.isSuspended = false
        try wait(for: recorder.finished, timeout: 0.5)
    }
}
