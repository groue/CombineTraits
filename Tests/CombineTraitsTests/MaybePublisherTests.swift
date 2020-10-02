import Combine
import CombineTraits
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
        let publisher = Empty<Int, Never>().checkMaybe()
        
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
        let publisher = Empty<Int, Never>(completeImmediately: false).checkMaybe()
        
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
            synchronouslyCompletesWithResult: .empty)
        
        test(
            publisher: Fail(outputType: Int.self, failure: TestError()),
            synchronouslyCompletesWithResult: .failure(TestError()))
    }
    
    // MARK: - Maybe Publisher Relationships
    
    func test_relationships() {
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
    
    // MARK: - Composition
    
    func test_publishers() {
        struct TestError: Error { }
        
        let publisher = [1, 2, 3].publisher
        let failingPublisher = publisher.setFailureType(to: Error.self)
        let maybe = Just(1)
        let failingMaybe = maybe.setFailureType(to: Error.self)

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
        XCTAssertFalse(isMaybe(publisher.makeConnectable().autoconnect()))
        XCTAssertTrue(isMaybe(maybe.makeConnectable().autoconnect()))
        
        // Publishers.Breakpoint
        XCTAssertFalse(isMaybe(publisher.breakpoint()))
        XCTAssertTrue(isMaybe(maybe.breakpoint()))
        
        // Publishers.Catch
        XCTAssertFalse(isMaybe(failingPublisher.catch { _ in publisher }))
        XCTAssertFalse(isMaybe(failingPublisher.catch { _ in maybe }))
        XCTAssertFalse(isMaybe(failingMaybe.catch { _ in publisher }))
        XCTAssertTrue(isMaybe(failingMaybe.catch { _ in maybe }))
        
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
    }
}

private func isMaybe<P: Publisher>(_ p: P) -> Bool { false }
private func isMaybe<P: MaybePublisher>(_ p: P) -> Bool { true }
