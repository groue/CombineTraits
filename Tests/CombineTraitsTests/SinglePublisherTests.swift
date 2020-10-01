import Combine
import CombineTraits
import XCTest

class SinglePublisherTests: XCTestCase {
    // MARK: - CheckSinglePublisher
    
    func test_CheckSinglePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().checkSingle()
        
        var completion: Subscribers.Completion<SingleError<Never>>?
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
    
    func test_CheckSinglePublisher_Empty() throws {
        let publisher = Empty<Int, Never>().checkSingle()
        
        var completion: Subscribers.Completion<SingleError<Never>>?
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
                case .missingElement:
                    break
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }
    
    func test_CheckSinglePublisher_EmptyWithoutCompletion() throws {
        let publisher = Empty<Int, Never>(completeImmediately: false).checkSingle()
        
        var completion: Subscribers.Completion<SingleError<Never>>?
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
    
    func test_CheckSinglePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().checkSingle()
        
        var completion: Subscribers.Completion<SingleError<TestError>>?
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
    
    func test_CheckSinglePublisher_ElementThenFailure() throws {
        struct TestError: Error { }
        let subject = PassthroughSubject<Int, TestError>()
        let publisher = subject.checkSingle()
        
        var completion: Subscribers.Completion<SingleError<TestError>>?
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
    
    func test_CheckSinglePublisher_TooManyElements() throws {
        let publisher = [1, 2].publisher.checkSingle()
        
        var completion: Subscribers.Completion<SingleError<Never>>?
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
    
    func test_CheckSinglePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.checkSingle()
        
        var completion: Subscribers.Completion<SingleError<TestError>>?
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
    
    // MARK: - AssertNoSingleFailurePublisher
    
    func test_AssertNoSingleFailurePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().assertSingle()
        
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
    
    func test_AssertNoSingleFailurePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().assertSingle()
        
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
    
    func test_AssertNoSingleFailurePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.assertSingle()
        
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
    
    // MARK: - Canonical Single Publishers
    
    func test_AnySinglePublisher_never() {
        let publisher = AnySinglePublisher<Int, Never>.never()
        
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
    
    func test_canonical_just_types() {
        // The test passes if the test compiles
        
        func accept1(_ p: AnySinglePublisher<Int, Never>) { }
        func accept2(_ p: AnySinglePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnySinglePublisher.just(1)
        let p2 = AnySinglePublisher.just(1, failureType: Error.self)
        let p3 = AnySinglePublisher<Int, Error>.just(1)
        
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
        
        func accept1(_ p: AnySinglePublisher<Int, Never>) { }
        func accept2(_ p: AnySinglePublisher<Int, Error>) { }
        func accept3(_ p: AnySinglePublisher<Never, Never>) { }
        
        // The various ways to build a publisher...
        let p1 = AnySinglePublisher.never(outputType: Int.self, failureType: Error.self)
        let p2 = AnySinglePublisher<Int, Error>.never()
        
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
        func accept1(_ p: AnySinglePublisher<Never, Error>) { }
        func accept2(_ p: AnySinglePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnySinglePublisher.fail(TestError() as Error, outputType: Int.self)
        let p2 = AnySinglePublisher<Int, Error>.fail(TestError())
        
        // ... build the expected types.
        accept2(p1)
        accept2(p2)
        
        // Shorthand notation thanks to type inference
        accept1(.fail(TestError()))
        accept2(.fail(TestError()))
    }
    
    // MARK: - sinkSingle
    
    func test_sinkSingle() {
        func test<P: SinglePublisher>(publisher: P, synchronouslyCompletesWithResult expectedResult: Result<P.Output, P.Failure>)
        where P.Output: Equatable, P.Failure: Equatable
        {
            var result: Result<P.Output, P.Failure>?
            _ = publisher.sinkSingle(receive: { result = $0 })
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
