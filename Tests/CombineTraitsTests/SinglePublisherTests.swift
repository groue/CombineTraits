import Combine
@testable import CombineTraits
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
    
    func test_CheckSinglePublisher_usage() {
        // The test passes if the test compiles
        
        do {
            let nameSubject = PassthroughSubject<String, Error>()
            let publisher = nameSubject.prefix(1)
            let singlePublisher = publisher.checkSingle()
            _ = singlePublisher.sinkSingle { result in
                switch result {
                case .success: break
                case let .failure(error):
                    switch error {
                    case .missingElement: break
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
            let singlePublisher = publisher.checkSingle()
            _ = singlePublisher.sinkSingle { result in
                switch result {
                case .success: break
                case let .failure(error):
                    switch error {
                    case .missingElement: break
                    case .tooManyElements: break
                    case .bothElementAndError: break
                    }
                }
            }
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
    
    // MARK: - Single Publisher Type Relationships
    
    func test_type_relationships() {
        // This test passes if this test compiles
        
        func acceptSomeMaybePublisher<P: MaybePublisher>(_ p: P) {
            acceptAnyMaybePublisher(p.eraseToAnyMaybePublisher())
        }
        
        func acceptSomeSinglePublisher<P: SinglePublisher>(_ p: P) {
            acceptAnyMaybePublisher(p.eraseToAnyMaybePublisher())
            acceptAnySinglePublisher(p.eraseToAnySinglePublisher())
            acceptSomeMaybePublisher(p)
        }
        
        func acceptAnyMaybePublisher<Output, Failure>(_ p: AnyMaybePublisher<Output, Failure>) {
            acceptSomeMaybePublisher(p)
        }
        
        func acceptAnySinglePublisher<Output, Failure>(_ p: AnySinglePublisher<Output, Failure>) {
            acceptSomeMaybePublisher(p)
            acceptSomeSinglePublisher(p)
        }
        
        func acceptSomePublisher<P: Publisher>(_ p: P) {
            acceptAnyMaybePublisher(p.uncheckedMaybe())
            acceptAnySinglePublisher(p.uncheckedSingle())
            acceptSomeMaybePublisher(p.assertMaybe())
            acceptSomeMaybePublisher(p.assertSingle())
            acceptSomeMaybePublisher(p.checkMaybe())
            acceptSomeMaybePublisher(p.checkSingle())
            acceptSomeMaybePublisher(p.uncheckedMaybe())
            acceptSomeMaybePublisher(p.uncheckedSingle())
            acceptSomeSinglePublisher(p.assertSingle())
            acceptSomeSinglePublisher(p.checkSingle())
            acceptSomeSinglePublisher(p.uncheckedSingle())
        }
    }
    
    // MARK: - Built-in Maybes
    
    func test_built_in_maybes() {
        struct TestError: Error { }
        
        let publisher = [1, 2, 3].publisher.eraseToAnyPublisher()
        let failingPublisher = publisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let maybe = Empty<Int, Never>().eraseToAnyMaybePublisher()
        let failingMaybe = maybe.setFailureType(to: Error.self).eraseToAnyMaybePublisher()
        let single = Just(1).eraseToAnySinglePublisher()
        let failingSingle = single.setFailureType(to: Error.self).eraseToAnySinglePublisher()
        
        XCTAssertFalse(isMaybe(publisher))
        XCTAssertFalse(isMaybe(failingPublisher))
        XCTAssertTrue(isMaybe(maybe))
        XCTAssertTrue(isMaybe(failingMaybe))
        XCTAssertTrue(isMaybe(single))
        XCTAssertTrue(isMaybe(failingSingle))
        
        XCTAssertFalse(isSingle(publisher))
        XCTAssertFalse(isSingle(failingPublisher))
        XCTAssertFalse(isSingle(maybe))
        XCTAssertFalse(isSingle(failingMaybe))
        XCTAssertTrue(isSingle(single))
        XCTAssertTrue(isSingle(failingSingle))
        
        // Publishers.AllSatisfy
        XCTAssertTrue(isSingle(publisher.allSatisfy { _ in true }))
        
        // Publishers.AssertNoFailure
        XCTAssertFalse(isSingle(failingPublisher.assertNoFailure()))
        XCTAssertFalse(isSingle(failingMaybe.assertNoFailure()))
        XCTAssertTrue(isSingle(failingSingle.assertNoFailure()))
        
        // Publishers.Autoconnect
        // Publishers.MakeConnectable
        XCTAssertFalse(isSingle(publisher.makeConnectable().autoconnect()))
        XCTAssertFalse(isSingle(maybe.makeConnectable().autoconnect()))
        XCTAssertTrue(isSingle(single.makeConnectable().autoconnect()))
        
        // Publishers.Breakpoint
        XCTAssertFalse(isSingle(publisher.breakpoint()))
        XCTAssertFalse(isSingle(maybe.breakpoint()))
        XCTAssertTrue(isSingle(single.breakpoint()))
        
        // Publishers.Catch
        XCTAssertFalse(isSingle(failingPublisher.catch { _ in publisher }))
        XCTAssertFalse(isSingle(failingPublisher.catch { _ in maybe }))
        XCTAssertFalse(isSingle(failingPublisher.catch { _ in single }))
        XCTAssertFalse(isSingle(failingMaybe.catch { _ in publisher }))
        XCTAssertFalse(isSingle(failingMaybe.catch { _ in maybe }))
        XCTAssertFalse(isSingle(failingMaybe.catch { _ in single }))
        XCTAssertFalse(isSingle(failingSingle.catch { _ in publisher }))
        XCTAssertFalse(isSingle(failingSingle.catch { _ in maybe }))
        XCTAssertTrue(isSingle(failingSingle.catch { _ in single }))
        
        // Publishers.Collect
        XCTAssertTrue(isSingle(publisher.collect()))
        
        // Publishers.CombineLatest
        XCTAssertFalse(isSingle(publisher.combineLatest(publisher)))
        XCTAssertFalse(isSingle(publisher.combineLatest(maybe)))
        XCTAssertFalse(isSingle(publisher.combineLatest(single)))
        XCTAssertFalse(isSingle(maybe.combineLatest(publisher)))
        XCTAssertFalse(isSingle(maybe.combineLatest(maybe)))
        XCTAssertFalse(isSingle(maybe.combineLatest(single)))
        XCTAssertFalse(isSingle(single.combineLatest(publisher)))
        XCTAssertFalse(isSingle(single.combineLatest(maybe)))
        XCTAssertTrue(isSingle(single.combineLatest(single)))
        
        // Publishers.CombineLatest3
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(publisher, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(maybe, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest3(single, single, maybe)))
        XCTAssertTrue(isSingle(Publishers.CombineLatest3(single, single, single)))
        
        // Publishers.CombineLatest4
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, publisher, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, maybe, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(publisher, single, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, publisher, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, maybe, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(maybe, single, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, publisher, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, single, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, maybe, single, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, publisher, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, publisher, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, publisher, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, maybe, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, maybe, maybe)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, maybe, single)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, single, publisher)))
        XCTAssertFalse(isSingle(Publishers.CombineLatest4(single, single, single, maybe)))
        XCTAssertTrue(isSingle(Publishers.CombineLatest4(single, single, single, single)))
        
        // Publishers.CompactMap
        XCTAssertFalse(isSingle(publisher.compactMap { $0 }))
        XCTAssertFalse(isSingle(maybe.compactMap { $0 }))
        XCTAssertFalse(isSingle(single.compactMap { $0 }))
        XCTAssertTrue(isMaybe(single.compactMap { $0 }))
        
        // Publishers.Contains
        XCTAssertTrue(isSingle(publisher.contains(1)))
        
        // Publishers.ContainsWhere
        XCTAssertTrue(isSingle(publisher.contains { _ in true }))
        
        // Publishers.Count
        XCTAssertTrue(isSingle(publisher.count()))
        
        // Publishers.Decode
        struct Decoder<Input>: TopLevelDecoder {
            func decode<T>(_ type: T.Type, from: Input) throws -> T where T: Decodable { fatalError() }
        }
        XCTAssertFalse(isSingle(publisher.decode(type: String.self, decoder: Decoder())))
        XCTAssertFalse(isSingle(maybe.decode(type: String.self, decoder: Decoder())))
        XCTAssertTrue(isSingle(single.decode(type: String.self, decoder: Decoder())))
        
        // Publishers.Delay
        XCTAssertFalse(isSingle(publisher.delay(for: 1, scheduler: DispatchQueue.main)))
        XCTAssertFalse(isSingle(maybe.delay(for: 1, scheduler: DispatchQueue.main)))
        XCTAssertTrue(isSingle(single.delay(for: 1, scheduler: DispatchQueue.main)))
        
        // Publishers.Encode
        struct Encoder: TopLevelEncoder {
            func encode<T>(_ value: T) throws -> Void where T : Encodable { }
        }
        XCTAssertFalse(isSingle(publisher.encode(encoder: Encoder())))
        XCTAssertFalse(isSingle(maybe.encode(encoder: Encoder())))
        XCTAssertTrue(isSingle(single.encode(encoder: Encoder())))
        
        // Publishers.Filter
        XCTAssertFalse(isSingle(publisher.filter { _ in true }))
        XCTAssertFalse(isSingle(maybe.filter { _ in true }))
        XCTAssertFalse(isSingle(single.filter { _ in true }))
        XCTAssertTrue(isMaybe(single.filter { _ in true }))
        
        // Publishers.FlatMap
        XCTAssertFalse(isSingle(publisher.flatMap { _ in publisher }))
        XCTAssertFalse(isSingle(publisher.flatMap { _ in maybe }))
        XCTAssertFalse(isSingle(publisher.flatMap { _ in single }))
        XCTAssertFalse(isSingle(maybe.flatMap { _ in publisher }))
        XCTAssertFalse(isSingle(maybe.flatMap { _ in maybe }))
        XCTAssertFalse(isSingle(maybe.flatMap { _ in single }))
        XCTAssertFalse(isSingle(single.flatMap { _ in publisher }))
        XCTAssertFalse(isSingle(single.flatMap { _ in maybe }))
        XCTAssertTrue(isSingle(single.flatMap { _ in single }))
        
        // Publishers.HandleEvents
        XCTAssertFalse(isSingle(publisher.handleEvents()))
        XCTAssertFalse(isSingle(maybe.handleEvents()))
        XCTAssertTrue(isSingle(single.handleEvents()))
        
        // Publishers.MakeConnectable
        XCTAssertFalse(isSingle(publisher.makeConnectable()))
        XCTAssertFalse(isSingle(maybe.makeConnectable()))
        XCTAssertTrue(isSingle(single.makeConnectable()))
        
        // Publishers.Map
        XCTAssertFalse(isSingle(publisher.map { $0 }))
        XCTAssertFalse(isSingle(maybe.map { $0 }))
        XCTAssertTrue(isSingle(single.map { $0 }))
        
        // Publishers.MapError
        XCTAssertFalse(isSingle(failingPublisher.mapError { $0 }))
        XCTAssertFalse(isSingle(failingMaybe.mapError { $0 }))
        XCTAssertTrue(isSingle(failingSingle.mapError { $0 }))
        
        // Publishers.MapKeyPath
        XCTAssertFalse(isSingle(publisher.map(\.self)))
        XCTAssertFalse(isSingle(maybe.map(\.self)))
        XCTAssertTrue(isSingle(single.map(\.self)))
        
        // Publishers.MapKeyPath2
        XCTAssertFalse(isSingle(publisher.map(\.self, \.self)))
        XCTAssertFalse(isSingle(maybe.map(\.self, \.self)))
        XCTAssertTrue(isSingle(single.map(\.self, \.self)))
        
        // Publishers.MapKeyPath3
        XCTAssertFalse(isSingle(publisher.map(\.self, \.self, \.self)))
        XCTAssertFalse(isSingle(maybe.map(\.self, \.self, \.self)))
        XCTAssertTrue(isSingle(single.map(\.self, \.self, \.self)))
        
        // Publishers.Print
        XCTAssertFalse(isSingle(publisher.print()))
        XCTAssertFalse(isSingle(maybe.print()))
        XCTAssertTrue(isSingle(single.print()))
        
        // Publishers.ReceiveOn
        XCTAssertFalse(isSingle(publisher.receive(on: DispatchQueue.main)))
        XCTAssertFalse(isSingle(maybe.receive(on: DispatchQueue.main)))
        XCTAssertTrue(isSingle(single.receive(on: DispatchQueue.main)))
        
        // Publishers.Reduce
        XCTAssertTrue(isSingle(publisher.reduce(0) { $0 + $1 }))
        
        // Publishers.ReplaceEmpty
        XCTAssertFalse(isSingle(publisher.replaceEmpty(with: 0)))
        XCTAssertTrue(isSingle(maybe.replaceEmpty(with: 0)))
        XCTAssertTrue(isSingle(single.replaceEmpty(with: 0)))
        
        // Publishers.ReplaceError
        XCTAssertFalse(isSingle(failingPublisher.replaceError(with: 0)))
        XCTAssertFalse(isSingle(failingMaybe.replaceError(with: 0)))
        XCTAssertTrue(isSingle(failingSingle.replaceError(with: 0)))
        
        // Publishers.Retry
        XCTAssertFalse(isSingle(failingPublisher.retry(1)))
        XCTAssertFalse(isSingle(failingMaybe.retry(1)))
        XCTAssertTrue(isSingle(failingSingle.retry(1)))
        
        // Publishers.SetFailureType
        XCTAssertFalse(isSingle(publisher.setFailureType(to: Error.self)))
        XCTAssertFalse(isSingle(maybe.setFailureType(to: Error.self)))
        XCTAssertTrue(isSingle(single.setFailureType(to: Error.self)))
        
        // Publishers.Share
        XCTAssertFalse(isSingle(publisher.share()))
        XCTAssertFalse(isSingle(maybe.share()))
        XCTAssertTrue(isSingle(single.share()))
        
        // Publishers.SubscribeOn
        XCTAssertFalse(isSingle(publisher.subscribe(on: DispatchQueue.main)))
        XCTAssertFalse(isSingle(maybe.subscribe(on: DispatchQueue.main)))
        XCTAssertTrue(isSingle(single.subscribe(on: DispatchQueue.main)))
        
        // Publishers.SwitchToLatest
        XCTAssertFalse(isSingle([publisher].publisher.switchToLatest()))
        XCTAssertFalse(isSingle([maybe].publisher.switchToLatest()))
        XCTAssertFalse(isSingle([single].publisher.switchToLatest()))
        XCTAssertFalse(isSingle(Just(publisher).switchToLatest()))
        XCTAssertFalse(isSingle(Just(maybe).switchToLatest()))
        XCTAssertTrue(isSingle(Just(single).switchToLatest()))
        
        // Publishers.Timeout
        XCTAssertFalse(isSingle(publisher.timeout(1, scheduler: DispatchQueue.main)))
        XCTAssertFalse(isSingle(maybe.timeout(1, scheduler: DispatchQueue.main)))
        XCTAssertTrue(isSingle(single.timeout(1, scheduler: DispatchQueue.main)))
        
        // Publishers.TryAllSatisfy
        XCTAssertTrue(isSingle(publisher.tryAllSatisfy { _ in true }))
        
        // Publishers.TryCatch
        XCTAssertFalse(isSingle(failingPublisher.tryCatch { _ in publisher }))
        XCTAssertFalse(isSingle(failingPublisher.tryCatch { _ in maybe }))
        XCTAssertFalse(isSingle(failingPublisher.tryCatch { _ in single }))
        XCTAssertFalse(isSingle(failingMaybe.tryCatch { _ in publisher }))
        XCTAssertFalse(isSingle(failingMaybe.tryCatch { _ in maybe }))
        XCTAssertFalse(isSingle(failingMaybe.tryCatch { _ in single }))
        XCTAssertFalse(isSingle(failingSingle.tryCatch { _ in publisher }))
        XCTAssertFalse(isSingle(failingSingle.tryCatch { _ in maybe }))
        XCTAssertTrue(isSingle(failingSingle.tryCatch { _ in single }))
        
        // Publishers.TryCompactMap
        XCTAssertFalse(isSingle(publisher.tryCompactMap { $0 }))
        XCTAssertFalse(isSingle(maybe.tryCompactMap { $0 }))
        XCTAssertFalse(isSingle(single.tryCompactMap { $0 }))
        XCTAssertTrue(isMaybe(single.tryCompactMap { $0 }))
        
        // Publishers.TryContainsWhere
        XCTAssertTrue(isSingle(publisher.tryContains { _ in true }))
        
        // Publishers.TryFilter
        XCTAssertFalse(isSingle(publisher.tryFilter { _ in true }))
        XCTAssertFalse(isSingle(maybe.tryFilter { _ in true }))
        XCTAssertFalse(isSingle(single.tryFilter { _ in true }))
        XCTAssertTrue(isMaybe(single.tryFilter { _ in true }))
        
        // Publishers.TryMap
        XCTAssertFalse(isSingle(publisher.tryMap { $0 }))
        XCTAssertFalse(isSingle(maybe.tryMap { $0 }))
        XCTAssertTrue(isSingle(single.tryMap { $0 }))
        
        // Publishers.TryReduce
        XCTAssertTrue(isSingle(publisher.tryReduce(0) { $0 + $1 }))
        
        // Publishers.Zip
        XCTAssertFalse(isSingle(publisher.zip(publisher)))
        XCTAssertFalse(isSingle(publisher.zip(maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher)))
        XCTAssertFalse(isSingle(maybe.zip(maybe)))
        XCTAssertFalse(isSingle(maybe.zip(single)))
        XCTAssertTrue(isSingle(single.zip(single)))
        
        // Publishers.Zip3
        XCTAssertFalse(isSingle(publisher.zip(publisher, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, single)))
        XCTAssertFalse(isSingle(publisher.zip(single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, single)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, single)))
        XCTAssertFalse(isSingle(maybe.zip(single, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(single, single)))
        XCTAssertFalse(isSingle(single.zip(publisher, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, publisher)))
        XCTAssertFalse(isSingle(single.zip(maybe, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, single)))
        XCTAssertFalse(isSingle(single.zip(single, maybe)))
        XCTAssertTrue(isSingle(single.zip(single, single)))
        
        // Publishers.Zip4
        XCTAssertFalse(isSingle(publisher.zip(publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, maybe, single)))
        XCTAssertFalse(isSingle(publisher.zip(publisher, single, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, publisher, single)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, maybe, single)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, single, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, single, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(maybe, single, single)))
        XCTAssertFalse(isSingle(publisher.zip(single, publisher, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(single, maybe, publisher)))
        XCTAssertFalse(isSingle(publisher.zip(single, maybe, maybe)))
        XCTAssertFalse(isSingle(publisher.zip(single, maybe, single)))
        XCTAssertFalse(isSingle(publisher.zip(single, single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, publisher, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, publisher, single)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, maybe, single)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, single, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(publisher, single, single)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, publisher, single)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, maybe, single)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, single, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(maybe, single, single)))
        XCTAssertFalse(isSingle(maybe.zip(single, publisher, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(single, publisher, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(single, publisher, single)))
        XCTAssertFalse(isSingle(maybe.zip(single, maybe, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(single, maybe, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(single, maybe, single)))
        XCTAssertFalse(isSingle(maybe.zip(single, single, publisher)))
        XCTAssertFalse(isSingle(maybe.zip(single, single, maybe)))
        XCTAssertFalse(isSingle(maybe.zip(single, single, single)))
        XCTAssertFalse(isSingle(single.zip(publisher, publisher, maybe)))
        XCTAssertFalse(isSingle(single.zip(publisher, maybe, publisher)))
        XCTAssertFalse(isSingle(single.zip(publisher, maybe, maybe)))
        XCTAssertFalse(isSingle(single.zip(publisher, maybe, single)))
        XCTAssertFalse(isSingle(single.zip(publisher, single, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, publisher, publisher)))
        XCTAssertFalse(isSingle(single.zip(maybe, publisher, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, publisher, single)))
        XCTAssertFalse(isSingle(single.zip(maybe, maybe, publisher)))
        XCTAssertFalse(isSingle(single.zip(maybe, maybe, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, maybe, single)))
        XCTAssertFalse(isSingle(single.zip(maybe, single, publisher)))
        XCTAssertFalse(isSingle(single.zip(maybe, single, maybe)))
        XCTAssertFalse(isSingle(single.zip(maybe, single, single)))
        XCTAssertFalse(isSingle(single.zip(single, publisher, maybe)))
        XCTAssertFalse(isSingle(single.zip(single, maybe, publisher)))
        XCTAssertFalse(isSingle(single.zip(single, maybe, maybe)))
        XCTAssertFalse(isSingle(single.zip(single, maybe, single)))
        XCTAssertFalse(isSingle(single.zip(single, single, maybe)))
        XCTAssertTrue(isSingle(single.zip(single, single, single)))
        
        // Result.Publisher
        XCTAssertTrue(isSingle(Result<Int, Error>.success(1).publisher))
        
        // URLSession.DataTaskPublisher
        XCTAssertTrue(isSingle(URLSession(configuration: URLSessionConfiguration.default).dataTaskPublisher(for: URL(string: "http://example.org")!)))
        
        // Deferred
        XCTAssertFalse(isSingle(Deferred { publisher }))
        XCTAssertFalse(isSingle(Deferred { maybe }))
        XCTAssertTrue(isSingle(Deferred { single }))
        
        // Empty
        XCTAssertFalse(isSingle(Empty<Int, Error>()))
        
        // Fail
        XCTAssertTrue(isSingle(Fail<Int, Error>(error: TestError())))
        
        // Future
        XCTAssertTrue(isSingle(Future<Int, Error> { _ in }))
        
        // Just
        XCTAssertTrue(isSingle(Just(1)))
    }
}

private func isMaybe<P: Publisher>(_ p: P) -> Bool { false }
private func isMaybe<P: MaybePublisher>(_ p: P) -> Bool { true }
private func isSingle<P: Publisher>(_ p: P) -> Bool { false }
private func isSingle<P: SinglePublisher>(_ p: P) -> Bool { true }
