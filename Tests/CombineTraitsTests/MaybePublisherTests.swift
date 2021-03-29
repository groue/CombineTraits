import Combine
@testable import CombineTraits
import XCTest

class MaybePublisherTests: XCTestCase {
    // MARK: - CheckMaybePublisher
    
    func test_CheckMaybePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<Never>>?
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertEqual(value, 1)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func test_CheckMaybePublisher_Empty() throws {
        let publisher = Empty<Int, Never>().eraseToAnyPublisher().checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<Never>>?
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertNil(value)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func test_CheckMaybePublisher_EmptyWithoutCompletion() throws {
        let publisher = Empty<Int, Never>(completeImmediately: false).eraseToAnyPublisher().checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<Never>>?
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
    
    func test_CheckMaybePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<TestError>>?
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertNil(value)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                XCTFail("Expected error")
            case let .failure(error):
                switch error {
                case .upstream:
                    break
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }
    
    func test_CheckMaybePublisher_ElementThenFailure() throws {
        struct TestError: Error { }
        let subject = PassthroughSubject<Int, TestError>()
        let publisher = subject.checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<TestError>>?
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
        
        try withExtendedLifetime(cancellable) {
            subject.send(1)
            subject.send(completion: .failure(TestError()))
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertNil(value)
            switch try XCTUnwrap(completion) {
            case .finished:
                XCTFail("Expected error")
            case let .failure(error):
                switch error {
                case .bothElementAndError:
                    break
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }
    
    func test_CheckMaybePublisher_TooManyElements() throws {
        let publisher = [1, 2].publisher.checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<Never>>?
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertNil(value)
            switch try XCTUnwrap(completion) {
            case .finished:
                XCTFail("Expected error")
            case let .failure(error):
                switch error {
                case .tooManyElements:
                    break
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }
    
    func test_CheckMaybePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.checkMaybe()
        
        var completion: Subscribers.Completion<MaybeError<TestError>>?
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
    
    func test_CheckMaybePublisher_usage() {
        // The test passes if the test compiles
        
        do {
            let nameSubject = PassthroughSubject<String, Error>()
            let publisher = nameSubject.prefix(1)
            let maybePublisher = publisher.checkMaybe()
            _ = maybePublisher.sinkMaybe { result in
                switch result {
                case .finished: break
                case .success: break
                case let .failure(error):
                    switch error {
                    case .tooManyElements: break
                    case .bothElementAndError: break
                    case .upstream: break
                    }
                }
            }
        }
        
        do {
            let nameSubject = PassthroughSubject<String, Never>()
            let publisher = nameSubject.prefix(1)
            let maybePublisher = publisher.checkMaybe()
            _ = maybePublisher.sinkMaybe { result in
                switch result {
                case .finished: break
                case .success: break
                case let .failure(error):
                    switch error {
                    case .tooManyElements: break
                    case .bothElementAndError: break
                    }
                }
            }
        }
    }
    
    // MARK: - AssertNoMaybeFailurePublisher
    
    func test_AssertNoMaybeFailurePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().assertMaybe()
        
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertEqual(value, 1)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func test_AssertNoMaybeFailurePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().assertMaybe()
        
        var completion: Subscribers.Completion<TestError>?
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
            
            XCTAssertNil(value)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                XCTFail("Expected error")
            case .failure:
                break
            }
        }
    }
    
    func test_AssertNoMaybeFailurePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.assertMaybe()
        
        var completion: Subscribers.Completion<TestError>?
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
    
    // MARK: - Canonical Maybe Publishers
    
    func test_AnyMaybePublisher_empty() throws {
        let publisher = AnyMaybePublisher<Int, Never>.empty()
        
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
        
        try withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 0.5, handler: nil)
            
            XCTAssertNil(value)
            
            switch try XCTUnwrap(completion) {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func test_AnyMaybePublisher_never() {
        let publisher = AnyMaybePublisher<Int, Never>.never()
        
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
    
    func test_canonical_empty_types() {
        // The test passes if the test compiles
        
        func accept1(_ p: AnyMaybePublisher<Int, Never>) { }
        func accept2(_ p: AnyMaybePublisher<Int, Error>) { }
        func accept3(_ p: AnyMaybePublisher<Never, Never>) { }
        func accept4(_ p: AnyMaybePublisher<Never, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyMaybePublisher.empty(outputType: Int.self, failureType: Error.self)
        let p2 = AnyMaybePublisher<Int, Error>.empty()
        
        // ... build the expected types.
        accept2(p1)
        accept2(p2)
        
        // Shorthand notation thanks to type inference
        accept1(.empty())
        accept2(.empty())
        accept3(.empty())
        accept4(.empty())
    }
    
    func test_canonical_just_types() {
        // The test passes if the test compiles
        
        func accept1(_ p: AnyMaybePublisher<Int, Never>) { }
        func accept2(_ p: AnyMaybePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyMaybePublisher.just(1)
        let p2 = AnyMaybePublisher.just(1, failureType: Error.self)
        let p3 = AnyMaybePublisher<Int, Error>.just(1)
        
        // ... build the expected types.
        accept1(p1)
        accept2(p2)
        accept2(p3)
        
        // Shorthand notation thanks to type inference
        accept1(.just(1))
        accept2(.just(1))
    }
    
    func test_canonical_never_types() {
        // The test passes if the test compiles
        
        func accept1(_ p: AnyMaybePublisher<Int, Never>) { }
        func accept2(_ p: AnyMaybePublisher<Int, Error>) { }
        func accept3(_ p: AnyMaybePublisher<Never, Never>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyMaybePublisher.never(outputType: Int.self, failureType: Error.self)
        let p2 = AnyMaybePublisher<Int, Error>.never()
        
        // ... build the expected types.
        accept2(p1)
        accept2(p2)
        
        // Shorthand notation thanks to type inference
        accept1(.never())
        accept2(.never())
        accept3(.never())
    }
    
    func test_canonical_fail_types() {
        // The test passes if the test compiles
        
        struct TestError: Error { }
        func accept1(_ p: AnyMaybePublisher<Never, Error>) { }
        func accept2(_ p: AnyMaybePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyMaybePublisher.fail(TestError() as Error, outputType: Int.self)
        let p2 = AnyMaybePublisher<Int, Error>.fail(TestError())
        
        // ... build the expected types.
        accept2(p1)
        accept2(p2)
        
        // Shorthand notation thanks to type inference
        accept1(.fail(TestError()))
        accept2(.fail(TestError()))
    }
    
    // MARK: - replaceEmpty(withError:)
    
    func test_replaceEmpty_withError() throws {
        struct TestError: Error { }
        
        do {
            let publisher = AnyMaybePublisher<Int, TestError>
                .just(1)
                .replaceEmpty(withError: TestError())
                .eraseToAnySinglePublisher()
            
            var result: Result<Int, TestError>?
            _ = publisher.sinkSingle { result = $0 }
            
            do {
                _ = try XCTUnwrap(result).get()
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
        
        do {
            let publisher = AnyMaybePublisher<Int?, TestError>
                .just(nil)
                .replaceEmpty(withError: TestError())
                .eraseToAnySinglePublisher()
            
            var result: Result<Int?, TestError>?
            _ = publisher.sinkSingle { result = $0 }
            
            do {
                _ = try XCTUnwrap(result).get()
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
        
        do {
            let publisher = AnyMaybePublisher<Int, TestError>
                .empty()
                .replaceEmpty(withError: TestError())
                .eraseToAnySinglePublisher()
            
            var result: Result<Int, TestError>?
            _ = publisher.sinkSingle { result = $0 }
            
            do {
                _ = try XCTUnwrap(result).get()
                XCTFail("Expected error")
            } catch { }
        }
    }
    
    // MARK: - preventCancellation
    
    func test_preventCancellation_single() {
        // Returns a well-behaved publisher that does not publish any value
        // after a subscription has been cancelled.
        func makePublisher() -> AnyMaybePublisher<Void, Never> {
            // The two publisher belows are NOT well-behaved:
            //
            // - Just(Date()).receive(on: DispatchQueue.main)
            // - Just(Date()).delay(for: 0.01, scheduler: DispatchQueue.main)
            Timer
                .publish(every: 0.01, on: .main, in: .common)
                .autoconnect()
                .first()
                .map { _ in }
                .eraseToAnyMaybePublisher()
        }
        
        // Test that we can receive a result
        do {
            let expectation = self.expectation(description: "value received")
            expectation.expectedFulfillmentCount = 2
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should happen
                    expectation.fulfill()
                })
            withExtendedLifetime(cancellable) {
                wait(for: [expectation], timeout: 1)
            }
        }
        
        // Test that value is not produced when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "value not produced")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .handleEvents(receiveOutput: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any value when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "value not received")
            expectation.isInverted = true
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any value when the subscription is
        // cancelled, even with `preventCancellation`
        do {
            let expectation = self.expectation(description: "value not received")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .preventCancellation()
                .sink(
                    receiveCompletion: { _ in
                        // Should not happen
                        expectation.fulfill()
                    },
                    receiveValue: { _ in
                        // Should not happen
                        expectation.fulfill()
                    })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that value is produced when the subscription is cancelled and we
        // call `preventCancellation`.
        do {
            let expectation = self.expectation(description: "value produced")
            let cancellable = makePublisher()
                .handleEvents(receiveOutput: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .preventCancellation()
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 1)
        }
        
        // Test that value is produced when the cancellable is ignored and we
        // call `preventCancellation`.
        do {
            let expectation = self.expectation(description: "value produced")
            _ = makePublisher()
                .handleEvents(receiveOutput: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .preventCancellation()
                .sinkMaybe(receive: { _ in })
            wait(for: [expectation], timeout: 1)
        }
    }
    
    func test_preventCancellation_empty() {
        // Returns a well-behaved publisher that does not publish any completion
        // after a subscription has been cancelled.
        func makePublisher() -> AnyMaybePublisher<Void, Never> {
            AnyMaybePublisher
                .empty()
                .receive(on: DispatchQueue.main)
                .eraseToAnyMaybePublisher()
        }
        
        // Test that we can receive a completion
        do {
            let expectation = self.expectation(description: "completion received")
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should happen
                    XCTFail("Unexpected value")
                })
            withExtendedLifetime(cancellable) {
                wait(for: [expectation], timeout: 1)
            }
        }
        
        // Test that completion is not produced when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "completion not produced")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .handleEvents(receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any completion when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "completion not received")
            expectation.isInverted = true
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                },
                receiveValue: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any completion when the subscription is
        // cancelled, even with `preventCancellation`
        do {
            let expectation = self.expectation(description: "completion not received")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .preventCancellation()
                .sink(
                    receiveCompletion: { _ in
                        // Should not happen
                        expectation.fulfill()
                    },
                    receiveValue: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that completion is produced when the subscription is cancelled
        // and we call `preventCancellation`.
        do {
            let expectation = self.expectation(description: "completion produced")
            let cancellable = makePublisher()
                .handleEvents(receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .preventCancellation()
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 1)
        }
        
        // Test that completion is produced when the cancellable is ignored and
        // we call `preventCancellation`.
        do {
            let expectation = self.expectation(description: "completion produced")
            _ = makePublisher()
                .handleEvents(receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .preventCancellation()
                .sinkMaybe(receive: { _ in })
            wait(for: [expectation], timeout: 1)
        }
    }
    
    // MARK: - fireAndForget
    
    func test_fireAndForget_single() {
        // Returns a well-behaved publisher that does not publish any value
        // after a subscription has been cancelled.
        func makePublisher() -> AnyMaybePublisher<Void, Never> {
            // The two publisher belows are NOT well-behaved:
            //
            // - Just(Date()).receive(on: DispatchQueue.main)
            // - Just(Date()).delay(for: 0.01, scheduler: DispatchQueue.main)
            Timer
                .publish(every: 0.01, on: .main, in: .common)
                .autoconnect()
                .first()
                .map { _ in }
                .eraseToAnyMaybePublisher()
        }
        
        // Test that we can receive a result
        do {
            let expectation = self.expectation(description: "value received")
            expectation.expectedFulfillmentCount = 2
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should happen
                    expectation.fulfill()
                })
            withExtendedLifetime(cancellable) {
                wait(for: [expectation], timeout: 1)
            }
        }
        
        // Test that value is not produced when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "value not produced")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .handleEvents(receiveOutput: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any value when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "value not received")
            expectation.isInverted = true
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that value is produced with `fireAndForget`.
        do {
            let expectation = self.expectation(description: "value produced")
            makePublisher()
                .handleEvents(receiveOutput: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .ignoreOutput()
                .fireAndForget()
            wait(for: [expectation], timeout: 1)
        }
    }
    
    func test_fireAndForget_empty() {
        // Returns a well-behaved publisher that does not publish any completion
        // after a subscription has been cancelled.
        func makePublisher() -> AnyMaybePublisher<Void, Never> {
            AnyMaybePublisher
                .empty()
                .receive(on: DispatchQueue.main)
                .eraseToAnyMaybePublisher()
        }
        
        // Test that we can receive a completion
        do {
            let expectation = self.expectation(description: "completion received")
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Should happen
                    XCTFail("Unexpected value")
                })
            withExtendedLifetime(cancellable) {
                wait(for: [expectation], timeout: 1)
            }
        }
        
        // Test that completion is not produced when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "completion not produced")
            expectation.isInverted = true
            let cancellable = makePublisher()
                .handleEvents(receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                })
                .sinkMaybe(receive: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that we don't receive any completion when the subscription
        // is cancelled.
        do {
            let expectation = self.expectation(description: "completion not received")
            expectation.isInverted = true
            let cancellable = makePublisher().sink(
                receiveCompletion: { _ in
                    // Should not happen
                    expectation.fulfill()
                },
                receiveValue: { _ in })
            cancellable.cancel()
            wait(for: [expectation], timeout: 0.2)
        }
        
        // Test that completion is produced with `fireAndForget`.
        do {
            let expectation = self.expectation(description: "completion produced")
            makePublisher()
                .handleEvents(receiveCompletion: { _ in
                    // Should happen
                    expectation.fulfill()
                })
                .ignoreOutput()
                .fireAndForget()
            wait(for: [expectation], timeout: 1)
        }
    }

    // MARK: - sinkMaybe
    
    func test_sinkMaybe() {
        func test<P: MaybePublisher>(publisher: P, synchronouslyCompletesWithResult expectedResult: MaybeResult<P.Output, P.Failure>)
        where P.Output: Equatable, P.Failure: Equatable
        {
            var result: MaybeResult<P.Output, P.Failure>?
            _ = publisher.sinkMaybe(receive: { result = $0 })
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
    
    // MARK: - Maybe Publisher Type Relationships
    
    func test_type_relationships() {
        // This test passes if this test compiles
        
        func acceptSomeMaybePublisher<P: MaybePublisher>(_ p: P) {
            acceptAnyMaybePublisher(p.eraseToAnyMaybePublisher())
        }
        
        func acceptAnyMaybePublisher<Output, Failure>(_ p: AnyMaybePublisher<Output, Failure>) {
            acceptSomeMaybePublisher(p)
        }
        
        func acceptSomePublisher<P: Publisher>(_ p: P) {
            acceptAnyMaybePublisher(p.uncheckedMaybe())
            acceptSomeMaybePublisher(p.assertMaybe())
            acceptSomeMaybePublisher(p.checkMaybe())
            acceptSomeMaybePublisher(p.uncheckedMaybe())
        }
    }
    
    // MARK: - Built-in Maybe Publishers
    
    func test_built_in_maybe_publishers() {
        struct TestError: Error { }
        
        let publisher = [1, 2, 3].publisher.eraseToAnyPublisher()
        let failingPublisher = publisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let maybe = Empty<Int, Never>().eraseToAnyMaybePublisher()
        let failingMaybe = maybe.setFailureType(to: Error.self).eraseToAnyMaybePublisher()
        
        XCTAssertFalse(isMaybe(publisher))
        XCTAssertFalse(isMaybe(failingPublisher))
        XCTAssertTrue(isMaybe(maybe))
        XCTAssertTrue(isMaybe(failingMaybe))
        
        // Publishers.AllSatisfy
        XCTAssertTrue(isMaybe(publisher.allSatisfy { _ in true }))
        
        // Publishers.AssertNoFailure
        XCTAssertFalse(isMaybe(failingPublisher.assertNoFailure()))
        XCTAssertTrue(isMaybe(failingMaybe.assertNoFailure()))
        
        // Publishers.Autoconnect
        // Publishers.MakeConnectable
        XCTAssertFalse(isMaybe(publisher.makeConnectable().autoconnect()))
        XCTAssertTrue(isMaybe(maybe.makeConnectable().autoconnect()))
        
        // Publishers.Breakpoint
        XCTAssertFalse(isMaybe(publisher.breakpoint()))
        XCTAssertFalse(isMaybe(publisher.breakpointOnError()))
        XCTAssertTrue(isMaybe(maybe.breakpoint()))
        XCTAssertTrue(isMaybe(maybe.breakpointOnError()))
        
        // Publishers.Catch
        XCTAssertFalse(isMaybe(failingPublisher.catch { _ in publisher }))
        XCTAssertFalse(isMaybe(failingPublisher.catch { _ in maybe }))
        XCTAssertFalse(isMaybe(failingMaybe.catch { _ in publisher }))
        XCTAssertTrue(isMaybe(failingMaybe.catch { _ in maybe }))
        
        // Publishers.Collect
        XCTAssertTrue(isMaybe(publisher.collect()))
        
        // Publishers.CombineLatest
        XCTAssertFalse(isMaybe(publisher.combineLatest(publisher)))
        XCTAssertFalse(isMaybe(publisher.combineLatest(maybe)))
        XCTAssertFalse(isMaybe(maybe.combineLatest(publisher)))
        XCTAssertTrue(isMaybe(maybe.combineLatest(maybe)))
        
        // Publishers.CombineLatest3
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(publisher, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(publisher, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(publisher, maybe, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(publisher, maybe, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(maybe, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(maybe, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest3(maybe, maybe, publisher)))
        XCTAssertTrue(isMaybe(Publishers.CombineLatest3(maybe, maybe, maybe)))
        
        // Publishers.CombineLatest4
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, publisher, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, publisher, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, publisher, maybe, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, publisher, maybe, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, maybe, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, maybe, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, maybe, maybe, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(publisher, maybe, maybe, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, publisher, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, publisher, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, publisher, maybe, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, publisher, maybe, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, maybe, publisher, publisher)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, maybe, publisher, maybe)))
        XCTAssertFalse(isMaybe(Publishers.CombineLatest4(maybe, maybe, maybe, publisher)))
        XCTAssertTrue(isMaybe(Publishers.CombineLatest4(maybe, maybe, maybe, maybe)))
        
        // Publishers.CompactMap
        XCTAssertFalse(isMaybe(publisher.compactMap { $0 }))
        XCTAssertTrue(isMaybe(maybe.compactMap { $0 }))
        
        // Publishers.Contains
        XCTAssertTrue(isMaybe(publisher.contains(1)))
        
        // Publishers.ContainsWhere
        XCTAssertTrue(isMaybe(publisher.contains { _ in true }))
        
        // Publishers.Count
        XCTAssertTrue(isMaybe(publisher.count()))
        
        // Publishers.Decode
        struct Decoder<Input>: TopLevelDecoder {
            func decode<T>(_ type: T.Type, from: Input) throws -> T where T: Decodable { fatalError() }
        }
        XCTAssertFalse(isMaybe(publisher.decode(type: String.self, decoder: Decoder())))
        XCTAssertTrue(isMaybe(maybe.decode(type: String.self, decoder: Decoder())))
        
        // Publishers.Delay
        XCTAssertFalse(isMaybe(publisher.delay(for: 1, scheduler: DispatchQueue.main)))
        XCTAssertTrue(isMaybe(maybe.delay(for: 1, scheduler: DispatchQueue.main)))
        
        // Publishers.Encode
        struct Encoder: TopLevelEncoder {
            func encode<T>(_ value: T) throws -> Void where T : Encodable { }
        }
        XCTAssertFalse(isMaybe(publisher.encode(encoder: Encoder())))
        XCTAssertTrue(isMaybe(maybe.encode(encoder: Encoder())))
        
        // Publishers.Filter
        XCTAssertFalse(isMaybe(publisher.filter { _ in true }))
        XCTAssertTrue(isMaybe(maybe.filter { _ in true }))
        
        // Publishers.First
        XCTAssertTrue(isMaybe(publisher.first()))
        
        // Publishers.FirstWhere
        XCTAssertTrue(isMaybe(publisher.first { _ in true }))
        
        // Publishers.FlatMap
        XCTAssertFalse(isMaybe(publisher.flatMap { _ in publisher }))
        XCTAssertFalse(isMaybe(publisher.flatMap { _ in maybe }))
        XCTAssertFalse(isMaybe(maybe.flatMap { _ in publisher }))
        XCTAssertTrue(isMaybe(maybe.flatMap { _ in maybe }))
        
        // Publishers.HandleEvents
        XCTAssertFalse(isMaybe(publisher.handleEvents()))
        XCTAssertTrue(isMaybe(maybe.handleEvents()))
        
        // Publishers.IgnoreOutput
        XCTAssertTrue(isMaybe(publisher.ignoreOutput()))
        
        // Publishers.Last
        XCTAssertTrue(isMaybe(publisher.last()))
        
        // Publishers.LastWhere
        XCTAssertTrue(isMaybe(publisher.last { _ in true }))
        
        // Publishers.MakeConnectable
        XCTAssertFalse(isMaybe(publisher.makeConnectable()))
        XCTAssertTrue(isMaybe(maybe.makeConnectable()))
        
        // Publishers.Map
        XCTAssertFalse(isMaybe(publisher.map { $0 }))
        XCTAssertTrue(isMaybe(maybe.map { $0 }))
        
        // Publishers.MapError
        XCTAssertFalse(isMaybe(failingPublisher.mapError { $0 }))
        XCTAssertTrue(isMaybe(failingMaybe.mapError { $0 }))
        
        // Publishers.MapKeyPath
        XCTAssertFalse(isMaybe(publisher.map(\.self)))
        XCTAssertTrue(isMaybe(maybe.map(\.self)))
        
        // Publishers.MapKeyPath2
        XCTAssertFalse(isMaybe(publisher.map(\.self, \.self)))
        XCTAssertTrue(isMaybe(maybe.map(\.self, \.self)))
        
        // Publishers.MapKeyPath3
        XCTAssertFalse(isMaybe(publisher.map(\.self, \.self, \.self)))
        XCTAssertTrue(isMaybe(maybe.map(\.self, \.self, \.self)))
        
        // Publishers.Print
        XCTAssertFalse(isMaybe(publisher.print()))
        XCTAssertTrue(isMaybe(maybe.print()))
        
        // Publishers.ReceiveOn
        XCTAssertFalse(isMaybe(publisher.receive(on: DispatchQueue.main)))
        XCTAssertTrue(isMaybe(maybe.receive(on: DispatchQueue.main)))
        
        // Publishers.Reduce
        XCTAssertTrue(isMaybe(publisher.reduce(0) { $0 + $1 }))
        
        // Publishers.ReplaceEmpty
        XCTAssertFalse(isMaybe(publisher.replaceEmpty(with: 0)))
        XCTAssertTrue(isMaybe(maybe.replaceEmpty(with: 0)))
        
        // Publishers.ReplaceError
        XCTAssertFalse(isMaybe(failingPublisher.replaceError(with: 0)))
        XCTAssertTrue(isMaybe(failingMaybe.replaceError(with: 0)))
        
        // Publishers.Retry
        XCTAssertFalse(isMaybe(failingPublisher.retry(1)))
        XCTAssertTrue(isMaybe(failingMaybe.retry(1)))
        
        // Publishers.SetFailureType
        XCTAssertFalse(isMaybe(publisher.setFailureType(to: Error.self)))
        XCTAssertTrue(isMaybe(maybe.setFailureType(to: Error.self)))
        
        // Publishers.Share
        XCTAssertFalse(isMaybe(publisher.share()))
        XCTAssertTrue(isMaybe(maybe.share()))
        
        // Publishers.SubscribeOn
        XCTAssertFalse(isMaybe(publisher.subscribe(on: DispatchQueue.main)))
        XCTAssertTrue(isMaybe(maybe.subscribe(on: DispatchQueue.main)))
        
        // Publishers.SwitchToLatest
        XCTAssertFalse(isMaybe([publisher].publisher.switchToLatest()))
        XCTAssertFalse(isMaybe([maybe].publisher.switchToLatest()))
        XCTAssertFalse(isMaybe(Just(publisher).switchToLatest()))
        XCTAssertTrue(isMaybe(Just(maybe).switchToLatest()))
        
        // Publishers.Timeout
        XCTAssertFalse(isMaybe(publisher.timeout(1, scheduler: DispatchQueue.main)))
        XCTAssertTrue(isMaybe(maybe.timeout(1, scheduler: DispatchQueue.main)))
        
        // Publishers.TryAllSatisfy
        XCTAssertTrue(isMaybe(publisher.tryAllSatisfy { _ in true }))
        
        // Publishers.TryCatch
        XCTAssertFalse(isMaybe(failingPublisher.tryCatch { _ in publisher }))
        XCTAssertFalse(isMaybe(failingPublisher.tryCatch { _ in maybe }))
        XCTAssertFalse(isMaybe(failingMaybe.tryCatch { _ in publisher }))
        XCTAssertTrue(isMaybe(failingMaybe.tryCatch { _ in maybe }))
        
        // Publishers.TryCompactMap
        XCTAssertFalse(isMaybe(publisher.tryCompactMap { $0 }))
        XCTAssertTrue(isMaybe(maybe.tryCompactMap { $0 }))
        
        // Publishers.TryContainsWhere
        XCTAssertTrue(isMaybe(publisher.tryContains { _ in true }))
        
        // Publishers.TryFilter
        XCTAssertFalse(isMaybe(publisher.tryFilter { _ in true }))
        XCTAssertTrue(isMaybe(maybe.tryFilter { _ in true }))
        
        // Publishers.TryFirstWhere
        XCTAssertTrue(isMaybe(publisher.tryFirst { _ in true }))
        
        // Publishers.TryLastWhere
        XCTAssertTrue(isMaybe(publisher.tryLast { _ in true }))
        
        // Publishers.TryMap
        XCTAssertFalse(isMaybe(publisher.tryMap { $0 }))
        XCTAssertTrue(isMaybe(maybe.tryMap { $0 }))
        
        // Publishers.TryReduce
        XCTAssertTrue(isMaybe(publisher.tryReduce(0) { $0 + $1 }))
        
        // Publishers.Zip
        XCTAssertFalse(isMaybe(publisher.zip(publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher)))
        XCTAssertTrue(isMaybe(maybe.zip(maybe)))
        
        // Publishers.Zip3
        XCTAssertFalse(isMaybe(publisher.zip(publisher, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(publisher, maybe)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, publisher)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(maybe, publisher)))
        XCTAssertTrue(isMaybe(maybe.zip(maybe, maybe)))
        
        // Publishers.Zip4
        XCTAssertFalse(isMaybe(publisher.zip(publisher, publisher, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(publisher, publisher, maybe)))
        // XCTAssertTrue(isMaybe(publisher.zip(publisher, maybe, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(publisher, maybe, maybe)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, publisher, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, publisher, maybe)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, maybe, publisher)))
        // XCTAssertTrue(isMaybe(publisher.zip(maybe, maybe, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, publisher, publisher)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, publisher, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, maybe, publisher)))
        // XCTAssertTrue(isMaybe(maybe.zip(publisher, maybe, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(maybe, publisher, publisher)))
        // XCTAssertTrue(isMaybe(maybe.zip(maybe, publisher, maybe)))
        // XCTAssertTrue(isMaybe(maybe.zip(maybe, maybe, publisher)))
        XCTAssertTrue(isMaybe(maybe.zip(maybe, maybe, maybe)))
        
        // Result.Publisher
        XCTAssertTrue(isMaybe(Result<Int, Error>.success(1).publisher))
        
        // URLSession.DataTaskPublisher
        XCTAssertTrue(isMaybe(URLSession(configuration: URLSessionConfiguration.default).dataTaskPublisher(for: URL(string: "http://example.org")!)))
        
        // AnyPublisher where Output == Never
        XCTAssertTrue(isMaybe(Empty<Never, Error>().eraseToAnyPublisher()))
        
        // Deferred
        XCTAssertFalse(isMaybe(Deferred { publisher }))
        XCTAssertTrue(isMaybe(Deferred { maybe }))
        
        // Empty
        XCTAssertTrue(isMaybe(Empty<Int, Error>()))
        
        // Fail
        XCTAssertTrue(isMaybe(Fail<Int, Error>(error: TestError())))
        
        // Future
        XCTAssertTrue(isMaybe(Future<Int, Error> { _ in }))
        
        // Just
        XCTAssertTrue(isMaybe(Just(1)))
        
        // TraitPublishers.PreventCancellation
        XCTAssertTrue(isMaybe(maybe.preventCancellation()))
    }
}

private func isMaybe<P: Publisher>(_ p: P) -> Bool { false }
private func isMaybe<P: MaybePublisher>(_ p: P) -> Bool { true }
