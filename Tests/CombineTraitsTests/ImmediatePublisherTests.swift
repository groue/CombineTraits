import Combine
@testable import CombineTraits
import XCTest

class ImmediatePublisherTests: XCTestCase {
    // MARK: - CheckImmediatePublisher
    
    func test_CheckImmediatePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<Never>>?
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
    
    func test_CheckImmediatePublisher_Empty() throws {
        let publisher = Empty<Int, Never>().checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<Never>>?
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
    
    func test_CheckImmediatePublisher_EmptyWithoutCompletion() throws {
        let publisher = Empty<Int, Never>(completeImmediately: false).checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<Never>>?
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
                switch error {
                case .notImmediate:
                    break
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }
    
    func test_CheckImmediatePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<TestError>>?
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
    
    func test_CheckImmediatePublisher_ElementThenFailure() throws {
        struct TestError: Error { }
        let publisher = Record(output: [1], completion: .failure(TestError()))
            .eraseToAnyPublisher()
            .checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<TestError>>?
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
    
    func test_CheckImmediatePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.checkImmediate()
        
        var completion: Subscribers.Completion<ImmediateError<TestError>>?
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
            
            XCTAssertEqual(value, 1)
            XCTAssertNil(completion)
        }
    }
    
    // MARK: - AssertNoImmediateFailurePublisher
    
    func test_AssertNoImmediateFailurePublisher_Just() throws {
        let publisher = Just(1).eraseToAnyPublisher().assertImmediate()
        
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
    
    func test_AssertNoImmediateFailurePublisher_Fail() throws {
        struct TestError: Error { }
        let publisher = Fail<Int, TestError>(error: TestError()).eraseToAnyPublisher().assertImmediate()
        
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
    
    func test_AssertNoImmediateFailurePublisher_ElementWithoutCompletion() throws {
        struct TestError: Error { }
        let subject = CurrentValueSubject<Int, TestError>(1)
        let publisher = subject.assertImmediate()
        
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
            
            XCTAssertEqual(value, 1)
            XCTAssertNil(completion)
        }
    }
    
    // MARK: - Canonical Immediate Publishers
    
    func test_AnyImmediatePublisher_empty() throws {
        let publisher = AnyImmediatePublisher<Int, Never>.empty()
        
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
    
    func test_canonical_empty_types() {
        // The test passes if the test compiles
        
        func accept1(_ p: AnyImmediatePublisher<Int, Never>) { }
        func accept2(_ p: AnyImmediatePublisher<Int, Error>) { }
        func accept3(_ p: AnyImmediatePublisher<Never, Never>) { }
        func accept4(_ p: AnyImmediatePublisher<Never, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyImmediatePublisher.empty(outputType: Int.self, failureType: Error.self)
        let p2 = AnyImmediatePublisher<Int, Error>.empty()
        
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
        
        func accept1(_ p: AnyImmediatePublisher<Int, Never>) { }
        func accept2(_ p: AnyImmediatePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyImmediatePublisher.just(1)
        let p2 = AnyImmediatePublisher.just(1, failureType: Error.self)
        let p3 = AnyImmediatePublisher<Int, Error>.just(1)
        
        // ... build the expected types.
        accept1(p1)
        accept2(p2)
        accept2(p3)
        
        // Shorthand notation thanks to type inference
        accept1(.just(1))
        accept2(.just(1))
    }
    
    func test_canonical_fail_types() {
        // The test passes if the test compiles
        
        struct TestError: Error { }
        func accept1(_ p: AnyImmediatePublisher<Never, Error>) { }
        func accept2(_ p: AnyImmediatePublisher<Int, Error>) { }
        
        // The various ways to build a publisher...
        let p1 = AnyImmediatePublisher.fail(TestError() as Error, outputType: Int.self)
        let p2 = AnyImmediatePublisher<Int, Error>.fail(TestError())
        
        // ... build the expected types.
        accept2(p1)
        accept2(p2)
        
        // Shorthand notation thanks to type inference
        accept1(.fail(TestError()))
        accept2(.fail(TestError()))
    }
    
    // MARK: - Immediate Publisher Type Relationships
    
    func test_type_relationships() {
        // This test passes if this test compiles
        
        func acceptSomeImmediatePublisher<P: ImmediatePublisher>(_ p: P) {
            acceptAnyImmediatePublisher(p.eraseToAnyImmediatePublisher())
        }
        
        func acceptAnyImmediatePublisher<Output, Failure>(_ p: AnyImmediatePublisher<Output, Failure>) {
            acceptSomeImmediatePublisher(p)
        }
        
        func acceptSomePublisher<P: Publisher>(_ p: P) {
            acceptAnyImmediatePublisher(p.uncheckedImmediate())
            acceptSomeImmediatePublisher(p.assertImmediate())
            acceptSomeImmediatePublisher(p.checkImmediate())
            acceptSomeImmediatePublisher(p.uncheckedImmediate())
        }
    }
    
    // MARK: - Built-in Immediate Publishers
    
    func test_built_in_immediate_publishers() {
        struct TestError: Error { }
        
        let publisher = Just(1).eraseToAnyPublisher()
        let failingPublisher = publisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let immediate = AnyImmediatePublisher<Int, Never>.empty()
        let failingImmediate = immediate.setFailureType(to: Error.self).eraseToAnyImmediatePublisher()
        
        XCTAssertFalse(isImmediate(publisher))
        XCTAssertFalse(isImmediate(failingPublisher))
        XCTAssertTrue(isImmediate(immediate))
        XCTAssertTrue(isImmediate(failingImmediate))
        
        // Publishers.AssertNoFailure
        XCTAssertFalse(isImmediate(failingPublisher.assertNoFailure()))
        XCTAssertTrue(isImmediate(failingImmediate.assertNoFailure()))
        
        // Publishers.Breakpoint
        XCTAssertFalse(isImmediate(publisher.breakpoint()))
        XCTAssertFalse(isImmediate(publisher.breakpointOnError()))
        XCTAssertTrue(isImmediate(immediate.breakpoint()))
        XCTAssertTrue(isImmediate(immediate.breakpointOnError()))
        
        // Publishers.Catch
        XCTAssertFalse(isImmediate(failingPublisher.catch { _ in publisher }))
        XCTAssertFalse(isImmediate(failingPublisher.catch { _ in immediate }))
        XCTAssertFalse(isImmediate(failingImmediate.catch { _ in publisher }))
        XCTAssertTrue(isImmediate(failingImmediate.catch { _ in immediate }))
        
        // Publishers.CombineLatest
        XCTAssertFalse(isImmediate(publisher.combineLatest(publisher)))
        XCTAssertFalse(isImmediate(publisher.combineLatest(immediate)))
        XCTAssertFalse(isImmediate(immediate.combineLatest(publisher)))
        XCTAssertTrue(isImmediate(immediate.combineLatest(immediate)))
        
        // Publishers.CombineLatest3
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest3(immediate, immediate, publisher)))
        XCTAssertTrue(isImmediate(Publishers.CombineLatest3(immediate, immediate, immediate)))
        
        // Publishers.CombineLatest4
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, immediate, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(publisher, immediate, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.CombineLatest4(immediate, immediate, immediate, publisher)))
        XCTAssertTrue(isImmediate(Publishers.CombineLatest4(immediate, immediate, immediate, immediate)))
        
        // Publishers.Concatenate
        XCTAssertFalse(isImmediate(publisher.append(publisher)))
        XCTAssertFalse(isImmediate(publisher.append(immediate)))
        XCTAssertFalse(isImmediate(immediate.append(publisher)))
        XCTAssertTrue(isImmediate(immediate.append(immediate)))
        // XCTAssertTrue(isImmediate(publisher.prepend(1)))
        XCTAssertFalse(isImmediate(publisher.prepend([])))
        XCTAssertTrue(isImmediate(immediate.prepend(1)))
        XCTAssertTrue(isImmediate(immediate.prepend([])))
        
        // Publishers.Decode
        struct Decoder<Input>: TopLevelDecoder {
            func decode<T>(_ type: T.Type, from: Input) throws -> T where T: Decodable { fatalError() }
        }
        XCTAssertFalse(isImmediate(publisher.decode(type: String.self, decoder: Decoder())))
        XCTAssertTrue(isImmediate(immediate.decode(type: String.self, decoder: Decoder())))
        
        // Publishers.Encode
        struct Encoder: TopLevelEncoder {
            func encode<T>(_ value: T) throws -> Void where T : Encodable { }
        }
        XCTAssertFalse(isImmediate(publisher.encode(encoder: Encoder())))
        XCTAssertTrue(isImmediate(immediate.encode(encoder: Encoder())))
        
        // Publishers.First
        XCTAssertFalse(isImmediate(publisher.first()))
        XCTAssertTrue(isImmediate(immediate.first()))
        
        // Publishers.FlatMap
        XCTAssertFalse(isImmediate(publisher.flatMap { _ in publisher }))
        XCTAssertFalse(isImmediate(publisher.flatMap { _ in immediate }))
        XCTAssertFalse(isImmediate(immediate.flatMap { _ in publisher }))
        XCTAssertTrue(isImmediate(immediate.flatMap { _ in immediate }))
        
        // Publishers.HandleEvents
        XCTAssertFalse(isImmediate(publisher.handleEvents()))
        XCTAssertTrue(isImmediate(immediate.handleEvents()))
        
        // Publishers.Map
        XCTAssertFalse(isImmediate(publisher.map { $0 }))
        XCTAssertTrue(isImmediate(immediate.map { $0 }))
        
        // Publishers.MapError
        XCTAssertFalse(isImmediate(failingPublisher.mapError { $0 }))
        XCTAssertTrue(isImmediate(failingImmediate.mapError { $0 }))
        
        // Publishers.MapKeyPath
        XCTAssertFalse(isImmediate(publisher.map(\.self)))
        XCTAssertTrue(isImmediate(immediate.map(\.self)))
        
        // Publishers.MapKeyPath2
        XCTAssertFalse(isImmediate(publisher.map(\.self, \.self)))
        XCTAssertTrue(isImmediate(immediate.map(\.self, \.self)))
        
        // Publishers.MapKeyPath3
        XCTAssertFalse(isImmediate(publisher.map(\.self, \.self, \.self)))
        XCTAssertTrue(isImmediate(immediate.map(\.self, \.self, \.self)))
        
        // Publishers.Merge
        XCTAssertFalse(isImmediate(Publishers.Merge(publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge(publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge(immediate, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge(immediate, immediate)))
        
        // Publishers.Merge3
        XCTAssertFalse(isImmediate(Publishers.Merge3(publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge3(immediate, immediate, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge3(immediate, immediate, immediate)))
        
        // Publishers.Merge4
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, immediate, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(publisher, immediate, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(Publishers.Merge4(immediate, immediate, immediate, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge4(immediate, immediate, immediate, immediate)))
        
        // Publishers.Merge5
        XCTAssertFalse(isImmediate(Publishers.Merge5(publisher, publisher, publisher, publisher, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge5(immediate, immediate, immediate, immediate, immediate)))
        
        // Publishers.Merge6
        XCTAssertFalse(isImmediate(Publishers.Merge6(publisher, publisher, publisher, publisher, publisher, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge6(immediate, immediate, immediate, immediate, immediate, immediate)))
        
        // Publishers.Merge7
        XCTAssertFalse(isImmediate(Publishers.Merge7(publisher, publisher, publisher, publisher, publisher, publisher, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge7(immediate, immediate, immediate, immediate, immediate, immediate, immediate)))
        
        // Publishers.Merge8
        XCTAssertFalse(isImmediate(Publishers.Merge8(publisher, publisher, publisher, publisher, publisher, publisher, publisher, publisher)))
        XCTAssertTrue(isImmediate(Publishers.Merge8(immediate, immediate, immediate, immediate, immediate, immediate, immediate, immediate)))
        
        // Publishers.MergeMany
        XCTAssertFalse(isImmediate(Publishers.MergeMany(publisher, publisher)))
        XCTAssertTrue(isImmediate(Publishers.MergeMany(immediate, immediate)))
        
        // Publishers.Print
        XCTAssertFalse(isImmediate(publisher.print()))
        XCTAssertTrue(isImmediate(immediate.print()))
        
        // Publishers.RemoveDuplicates
        XCTAssertFalse(isImmediate(publisher.removeDuplicates()))
        XCTAssertTrue(isImmediate(immediate.removeDuplicates()))
        
        // Publishers.ReplaceEmpty
        XCTAssertFalse(isImmediate(publisher.replaceEmpty(with: 1)))
        XCTAssertTrue(isImmediate(immediate.replaceEmpty(with: 1)))
        
        // Publishers.ReplaceError
        XCTAssertFalse(isImmediate(failingPublisher.replaceError(with: 1)))
        XCTAssertTrue(isImmediate(failingImmediate.replaceError(with: 1)))
        
        // Publishers.Retry
        XCTAssertFalse(isImmediate(failingPublisher.retry(1)))
        XCTAssertTrue(isImmediate(failingImmediate.retry(1)))
        
        // Publishers.Scan
        XCTAssertFalse(isImmediate(publisher.scan(()) { _, _ in }))
        XCTAssertTrue(isImmediate(immediate.scan(()) { _, _ in }))
        
        // Publishers.Sequence
        XCTAssertTrue(isImmediate([1].publisher))
        
        // Publishers.SetFailureType
        XCTAssertFalse(isImmediate(publisher.setFailureType(to: Error.self)))
        XCTAssertTrue(isImmediate(immediate.setFailureType(to: Error.self)))
        
        // Publishers.SwitchToLatest
        XCTAssertFalse(isImmediate(Just(publisher).eraseToAnyPublisher().switchToLatest()))
        XCTAssertFalse(isImmediate(Just(immediate).eraseToAnyPublisher().switchToLatest()))
        XCTAssertFalse(isImmediate(Just(publisher).switchToLatest()))
        XCTAssertTrue(isImmediate(Just(immediate).switchToLatest()))
        
        // Publishers.TryCatch
        XCTAssertFalse(isImmediate(failingPublisher.tryCatch { _ in publisher }))
        XCTAssertFalse(isImmediate(failingPublisher.tryCatch { _ in immediate }))
        XCTAssertFalse(isImmediate(failingImmediate.tryCatch { _ in publisher }))
        XCTAssertTrue(isImmediate(failingImmediate.tryCatch { _ in immediate }))
        
        // Publishers.TryMap
        XCTAssertFalse(isImmediate(publisher.tryMap { $0 }))
        XCTAssertTrue(isImmediate(immediate.tryMap { $0 }))

        // Publishers.TryRemoveDuplicates
        XCTAssertFalse(isImmediate(publisher.tryRemoveDuplicates(by: <)))
        XCTAssertTrue(isImmediate(immediate.tryRemoveDuplicates(by: <)))
        
        // Publishers.TryScan
        XCTAssertFalse(isImmediate(publisher.tryScan(()) { _, _ in }))
        XCTAssertTrue(isImmediate(immediate.tryScan(()) { _, _ in }))

        // Publishers.Zip
        XCTAssertFalse(isImmediate(publisher.zip(publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher)))
        XCTAssertTrue(isImmediate(immediate.zip(immediate)))
        
        // Publishers.Zip3
        XCTAssertFalse(isImmediate(publisher.zip(publisher, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(publisher, immediate)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, publisher)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(immediate, publisher)))
        XCTAssertTrue(isImmediate(immediate.zip(immediate, immediate)))
        
        // Publishers.Zip4
        XCTAssertFalse(isImmediate(publisher.zip(publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(publisher.zip(publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, immediate, publisher)))
        XCTAssertFalse(isImmediate(publisher.zip(immediate, immediate, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, publisher, publisher)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, publisher, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, immediate, publisher)))
        XCTAssertFalse(isImmediate(immediate.zip(publisher, immediate, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(immediate, publisher, publisher)))
        XCTAssertFalse(isImmediate(immediate.zip(immediate, publisher, immediate)))
        XCTAssertFalse(isImmediate(immediate.zip(immediate, immediate, publisher)))
        XCTAssertTrue(isImmediate(immediate.zip(immediate, immediate, immediate)))

        // Result.Publisher
        XCTAssertTrue(isImmediate(Result<Int, Error>.success(1).publisher))

        // Deferred
        XCTAssertFalse(isImmediate(Deferred { publisher }))
        XCTAssertTrue(isImmediate(Deferred { immediate }))

        // Fail
        XCTAssertTrue(isImmediate(Fail<Int, Error>(error: TestError())))

        // Just
        XCTAssertTrue(isImmediate(Just(1)))

        // Record
        XCTAssertTrue(isImmediate(Record(output: [1], completion: .failure(TestError()))))
    }
}

private func isImmediate<P: Publisher>(_ p: P) -> Bool { false }
private func isImmediate<P: ImmediatePublisher>(_ p: P) -> Bool { true }
