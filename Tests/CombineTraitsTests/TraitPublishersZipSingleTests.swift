import Combine
import CombineExpectations
import CombineTraits
import XCTest

class TraitPublishersZipSingle: XCTestCase {
    func test_empty_collection() throws {
        let collection = [Just<Int>]()
        let publisher = collection.zipSingle()
        let recorder = publisher.record()
        let values = try recorder.single.get()
        XCTAssert(values.isEmpty)
    }
    
    func test_non_empty_collection_synchronous_success() throws {
        let collection = (0..<100).map { Just($0) }
        let publisher = collection.zipSingle()
        let recorder = publisher.record()
        let values = try recorder.single.get()
        XCTAssertEqual(values, Array(0..<100))
    }
    
    func test_non_empty_collection_synchronous_failure() throws {
        struct TestError: Error { }
        let collection: [AnySinglePublisher<Int, TestError>] = [
            .just(1),
            .fail(TestError()),
        ]
        let publisher = collection.zipSingle()
        let recorder = publisher.record()
        let completion: Subscribers.Completion<TestError> = try recorder.completion.get()
        if case .finished = completion {
            XCTFail("Expected failure")
        }
    }
    
    func test_non_empty_collection_asynchronous_success() throws {
        let collection = (0..<100).map {
            Just($0).receive(on: DispatchQueue.main)
        }
        let publisher = collection.zipSingle()
        let recorder = publisher.record()
        let values = try wait(for: recorder.single, timeout: 1)
        XCTAssertEqual(values, Array(0..<100))
    }
    
    func test_non_empty_collection_asynchronous_failure() throws {
        struct TestError: Error { }
        let collection: [AnySinglePublisher<Int, TestError>] = [
            AnySinglePublisher.just(1)
                .receive(on: DispatchQueue.main)
                .eraseToAnySinglePublisher(),
            AnySinglePublisher.fail(TestError())
                .receive(on: DispatchQueue.main)
                .eraseToAnySinglePublisher(),
        ]
        let publisher = collection.zipSingle()
        let recorder = publisher.record()
        let completion: Subscribers.Completion<TestError> = try wait(for: recorder.completion, timeout: 1)
        if case .finished = completion {
            XCTFail("Expected failure")
        }
    }
}
