import CancelBag
import Combine
import XCTest

final class CancelBagTests: XCTestCase {
    func testCancelBagExplicitCancel() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
            .store(in: cancelBag)
        
        XCTAssertFalse(isCancelled)
        cancelBag.cancel()
        XCTAssertTrue(isCancelled)
    }
    
    func testCancelBagExplicitCancelRetainingCancellable() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
        cancellable.store(in: cancelBag)
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(isCancelled)
            cancelBag.cancel()
            XCTAssertTrue(isCancelled)
        }
    }
    
    func testCancelBagImplicitCancelWhenDeinitialized() {
        var cancelBag: CancelBag? = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
            .store(in: cancelBag!)
        
        XCTAssertFalse(isCancelled)
        cancelBag = nil
        XCTAssertTrue(isCancelled)
    }
    
    func testCancelBagImplicitCancelWhenDeinitializedRetainingCancellable() {
        var cancelBag: CancelBag? = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
        cancellable.store(in: cancelBag!)
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(isCancelled)
            cancelBag = nil
            XCTAssertTrue(isCancelled)
        }
    }
    
    func testCancelBagAcceptsExternalCancellation() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
        cancellable.store(in: cancelBag)
        
        XCTAssertFalse(isCancelled)
        cancellable.cancel()
        XCTAssertTrue(isCancelled)
    }
    
    func testCancelBagAcceptsExternalCancellationRetainingCancellable() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(receiveValue: { _ in })
        cancellable.store(in: cancelBag)
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(isCancelled)
            cancellable.cancel()
            XCTAssertTrue(isCancelled)
        }
    }
    
    // MARK: - Sink
    
    func testCancelBagSinkJust() {
        let cancelBag = CancelBag()
        let publisher = Just(0)
        var isCancelled = false
        publisher
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(isCancelled)
        cancelBag.cancel()
        XCTAssertFalse(isCancelled) // too late
    }
    
    func testCancelBagSinkEmpty() {
        let cancelBag = CancelBag()
        let publisher = Empty(outputType: Void.self, failureType: Never.self)
        var isCancelled = false
        publisher
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(isCancelled)
        cancelBag.cancel()
        XCTAssertFalse(isCancelled) // too late
    }
    
    func testCancelBagSinkFail() {
        struct TestError: Error { }
        let cancelBag = CancelBag()
        let publisher = Fail(outputType: Void.self, failure: TestError())
        var isCancelled = false
        publisher
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag, receiveCompletion: { _ in }, receiveValue: { _ in })
        
        XCTAssertFalse(isCancelled)
        cancelBag.cancel()
        XCTAssertFalse(isCancelled) // too late
    }
    
    func testCancelBagSinkExplicitCancel() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(isCancelled)
        cancelBag.cancel()
        XCTAssertTrue(isCancelled)
    }
    
    func testCancelBagSinkExplicitCancelRetainingCancellable() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag, receiveValue: { _ in })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(isCancelled)
            cancelBag.cancel()
            XCTAssertTrue(isCancelled)
        }
    }
    
    func testCancelBagSinkImplicitCancelWhenDeinitialized() {
        var cancelBag: CancelBag? = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag!, receiveValue: { _ in })
        
        XCTAssertFalse(isCancelled)
        cancelBag = nil
        XCTAssertTrue(isCancelled)
    }
    
    func testCancelBagSinkImplicitCancelWhenDeinitializedRetainingCancellable() {
        var cancelBag: CancelBag? = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        var isCancelled = false
        let cancellable = subject
            .handleEvents(receiveCancel: { isCancelled = true })
            .sink(in: cancelBag!, receiveValue: { _ in })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(isCancelled)
            cancelBag = nil
            XCTAssertTrue(isCancelled)
        }
    }
    
    func testCancelBagSinkReleasesMemoryOnCancellation() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        subject.sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(cancelBag.isEmpty)
        cancelBag.cancel()
        XCTAssertTrue(cancelBag.isEmpty)
    }
    
    func testCancelBagSinkReleasesMemoryOnCancellationRetainingCancellable() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        let cancellable = subject.sink(in: cancelBag, receiveValue: { _ in })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(cancelBag.isEmpty)
            cancelBag.cancel()
            XCTAssertTrue(cancelBag.isEmpty)
        }
    }
    
    func testCancelBagSinkReleasesMemoryOnCompletionFinished() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        subject.sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(cancelBag.isEmpty)
        subject.send(completion: .finished)
        XCTAssertTrue(cancelBag.isEmpty)
    }
    
    func testCancelBagSinkEventuallyReleasesMemoryOnCompletionFinishedImmediate() {
        let cancelBag = CancelBag()
        let publisher = Empty<Void, Never>()
        publisher.sink(in: cancelBag, receiveValue: { _ in })
        
        XCTAssertFalse(cancelBag.isEmpty)
        
        let expectation = self.expectation(description: "Empty cancelBag")
        DispatchQueue.main.async {
            XCTAssertTrue(cancelBag.isEmpty)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelBagSinkReleasesMemoryOnCompletionFinishedRetainingCancellable() {
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, Never>()
        let cancellable = subject.sink(in: cancelBag, receiveValue: { _ in })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(cancelBag.isEmpty)
            subject.send(completion: .finished)
            XCTAssertTrue(cancelBag.isEmpty)
        }
    }
    
    func testCancelBagSinkReleasesMemoryOnCompletionFailure() {
        struct TestError: Error { }
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, TestError>()
        subject.sink(in: cancelBag, receiveCompletion: { _ in }, receiveValue: { _ in })
        
        XCTAssertFalse(cancelBag.isEmpty)
        subject.send(completion: .failure(TestError()))
        XCTAssertTrue(cancelBag.isEmpty)
    }
    
    func testCancelBagSinkEventuallyReleasesMemoryOnCompletionFailureImmediate() {
        struct TestError: Error { }
        let cancelBag = CancelBag()
        let publisher = Fail<Void, TestError>(error: TestError())
        publisher.sink(in: cancelBag, receiveCompletion: { _ in }, receiveValue: { _ in })
        
        XCTAssertFalse(cancelBag.isEmpty)
        
        let expectation = self.expectation(description: "Empty cancelBag")
        DispatchQueue.main.async {
            XCTAssertTrue(cancelBag.isEmpty)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelBagSinkReleasesMemoryOnCompletionFailureRetainingCancellable() {
        struct TestError: Error { }
        let cancelBag = CancelBag()
        let subject = PassthroughSubject<Void, TestError>()
        let cancellable = subject.sink(in: cancelBag, receiveCompletion: { _ in }, receiveValue: { _ in })
        
        withExtendedLifetime(cancellable) {
            XCTAssertFalse(cancelBag.isEmpty)
            subject.send(completion: .failure(TestError()))
            XCTAssertTrue(cancelBag.isEmpty)
        }
    }
}
