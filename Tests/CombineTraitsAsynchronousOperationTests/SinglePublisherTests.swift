import Combine
import CombineExpectations
import CombineTraits
import Foundation
import Dispatch
import XCTest

class SinglePublisherTests: XCTestCase {
    func test_makeOperation_handleCompletion_success() {
        let publisher = Just(1)
        let operation = publisher.makeOperation()
        let expectation = self.expectation(description: "")
        operation.handleCompletion { (result: Result<Int, Never>?) in
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
    
    func test_makeOperation_handleCompletion_failure() {
        struct TestError: Error { }
        let publisher = Fail<Never, TestError>(error: TestError())
        let operation = publisher.makeOperation()
        let expectation = self.expectation(description: "")
        operation.handleCompletion { (result: Result<Never, TestError>?) in
            if result == nil {
                XCTFail("Missing result")
                return
            }
            expectation.fulfill()
        }
        OperationQueue().addOperation(operation)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_makeOperation_handleCompletion_is_called_on_the_main_queue() {
        let publisher = Just(1)
        let operation = publisher.makeOperation()
        let expectation = self.expectation(description: "")
        operation.handleCompletion { result in
            dispatchPrecondition(condition: .onQueue(.main))
            expectation.fulfill()
        }
        OperationQueue().addOperation(operation)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_makeOperation_result_is_available_from_dependency() {
        let expectation = self.expectation(description: "")
        let publisher = Just(1)
        let operation1 = publisher.makeOperation()
        let operation2 = BlockOperation {
            guard let result = operation1.result,
                  case let .success(value) = result
            else {
                XCTFail("Missing result")
                return
            }
            XCTAssertEqual(value, 1)
            expectation.fulfill()
        }
        operation2.addDependency(operation1)
        OperationQueue().addOperation(operation1)
        OperationQueue().addOperation(operation2)
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
    
    func test_asOperation_is_scheduled_in_OperationQueue() throws {
        let queue = OperationQueue()
        queue.isSuspended = true
        let publisher = Just(1).asOperation(in: queue)
        let recorder = publisher.record()
        
        // Publisher does not publish if queue is suspended
        try wait(for: recorder.finished.inverted, timeout: 0.5)
        
        // Publisher does publish if queue is started
        queue.isSuspended = false
        try wait(for: recorder.finished, timeout: 1)
    }
    
    func test_asOperation_success() throws {
        let queue = OperationQueue()
        let publisher = Just(1).asOperation(in: queue)
        let recorder = publisher.record()
        let value = try wait(for: recorder.single, timeout: 1)
        XCTAssertEqual(value, 1)
    }
    
    func test_asOperation_failure() throws {
        let queue = OperationQueue()
        struct TestError: Error { }
        let publisher = Fail<Never, TestError>(error: TestError()).asOperation(in: queue)
        let recorder = publisher.record()
        let completion: Subscribers.Completion<TestError> = try wait(for: recorder.completion, timeout: 1)
        if case .finished = completion {
            XCTFail("Expected failure")
        }
    }
}
