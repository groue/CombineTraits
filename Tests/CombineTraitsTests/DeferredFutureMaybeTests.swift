import Combine
import CombineTraits
import XCTest

class DeferredFutureMaybeTests: XCTestCase {
    func test_DeferredFutureMaybe_is_a_MaybePublisher() {
        // This test passes if this test compiles
        func acceptSomeMaybePublisher<P: MaybePublisher>(_ p: P) { }
        func f<Output, Failure>(_ p: DeferredFutureMaybe<Output, Failure>) {
            acceptSomeMaybePublisher(p)
        }
    }
    
    func test_DeferredFutureMaybe_is_deferred() {
        var subscribed = false
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            subscribed = true
            return AnyCancellable({ })
        }
        
        XCTAssertFalse(subscribed)
        _ = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        XCTAssertTrue(subscribed)
    }
    
    func test_DeferredFutureMaybe_is_not_shared() {
        var subscriptionCount = 0
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            subscriptionCount += 1
            return AnyCancellable({ })
        }
        
        XCTAssertEqual(subscriptionCount, 0)
        _ = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        XCTAssertEqual(subscriptionCount, 1)
        _ = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        XCTAssertEqual(subscriptionCount, 2)
    }
    
    func test_DeferredFutureMaybe_as_never() {
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        let expectation = self.expectation(description: "completion")
        expectation.isInverted = true
        let cancellable = publisher.sink(
            receiveCompletion: {
                completion = $0
                expectation.fulfill()
            },
            receiveValue: {
                value = $0
            })
        
        withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 0.5, handler: nil)
            
            XCTAssertNil(value)
            XCTAssertNil(completion)
        }
    }
    
    func test_DeferredFutureMaybe_as_just() {
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            promise(.success(1))
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        _ = publisher.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { value = $0 })
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(completion, .finished)
    }
    
    func test_DeferredFutureMaybe_as_empty() {
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            promise(.finished)
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        _ = publisher.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { value = $0 })
        
        XCTAssertNil(value)
        XCTAssertEqual(completion, .finished)
    }
    
    func test_DeferredFutureMaybe_as_fail() {
        struct TestError: Error { }
        let publisher = DeferredFutureMaybe<Int, Error> { promise in
            promise(.failure(TestError()))
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Error>?
        var value: Int?
        _ = publisher.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { value = $0 })
        
        XCTAssertNil(value)
        switch completion {
        case .failure:
            break
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_DeferredFutureMaybe_as_delayed_just() {
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                promise(.success(1))
            }
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        let expectation = self.expectation(description: "completion")
        let cancellable = publisher.sink(
            receiveCompletion: {
                completion = $0
                expectation.fulfill()
            },
            receiveValue: {
                value = $0
            })
        
        withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 0.5, handler: nil)
            
            XCTAssertEqual(value, 1)
            XCTAssertEqual(completion, .finished)
        }
    }
    
    func test_DeferredFutureMaybe_as_delayed_empty() {
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                promise(.finished)
            }
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        let expectation = self.expectation(description: "completion")
        let cancellable = publisher.sink(
            receiveCompletion: {
                completion = $0
                expectation.fulfill()
            },
            receiveValue: {
                value = $0
            })
        
        withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 0.5, handler: nil)
            
            XCTAssertNil(value)
            XCTAssertEqual(completion, .finished)
        }
    }
    
    func test_DeferredFutureMaybe_as_delayed_fail() {
        struct TestError: Error { }
        let publisher = DeferredFutureMaybe<Int, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                promise(.failure(TestError()))
            }
            return AnyCancellable({ })
        }
        
        var completion: Subscribers.Completion<Error>?
        var value: Int?
        let expectation = self.expectation(description: "completion")
        let cancellable = publisher.sink(
            receiveCompletion: {
                completion = $0
                expectation.fulfill()
            },
            receiveValue: {
                value = $0
            })
        
        withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 0.5, handler: nil)
            
            XCTAssertNil(value)
            switch completion {
            case .failure:
                break
            default:
                XCTFail("Expected failure")
            }
        }
    }
    
    func test_cancellation_after_completion() {
        var disposed = false
        let publisher = DeferredFutureMaybe<Int, Error> { promise in
            promise(.success(1))
            return AnyCancellable({ disposed = true })
        }
        
        let cancellable = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ = $0 })
        
        withExtendedLifetime(cancellable) {
            XCTAssertTrue(disposed)
        }
    }
    
    func test_cancellation_before_completion() {
        var disposed = false
        let publisher = DeferredFutureMaybe<Int, Error> { promise in
            return AnyCancellable({ disposed = true })
        }
        
        let cancellable = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ = $0 })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(disposed)
            cancellable.cancel()
            XCTAssertTrue(disposed)
        }
    }
    
    func test_forwarding() {
        let upstream = Just(1)
        let publisher = DeferredFutureMaybe<Int, Never> { promise in
            return upstream.sinkMaybe(receive: promise)
        }
        
        var completion: Subscribers.Completion<Never>?
        var value: Int?
        _ = publisher.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { value = $0 })
        
        XCTAssertEqual(value, 1)
        XCTAssertEqual(completion, .finished)
    }
}
