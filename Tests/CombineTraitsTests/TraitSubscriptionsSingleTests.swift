import Combine
import CombineTraits
import XCTest

class TraitSubscriptionsSingleTests: XCTestCase {
    func test_canonical_subclass_compiles() {
        // Here we just test that the documented way to subclass compiles.
        typealias MyOutput = Int
        struct MyFailure: Error { }
        struct MyContext { }
        
        struct MySinglePublisher: SinglePublisher {
            typealias Output = MyOutput
            typealias Failure = MyFailure
            
            let context: MyContext
            
            func receive<S>(subscriber: S)
            where S: Subscriber, Failure == S.Failure, Output == S.Input
            {
                let subscription = Subscription(
                    downstream: subscriber,
                    context: context)
                subscriber.receive(subscription: subscription)
            }
            
            private class Subscription<Downstream: Subscriber>:
                TraitSubscriptions.Single<Downstream, MyContext>
            where
                Downstream.Input == Output,
                Downstream.Failure == Failure
            {
                override func start(with context: MyContext) { }
                override func didCancel(with context: MyContext) { }
                override func didComplete(with context: MyContext) { }
            }
        }
    }
    
    class Witness {
        var startCalled = false
        var didCancelCalled = false
        var didCompleteCalled = false
    }
    
    struct TestError: Error { }
    
    func test_completion_success() throws {
        struct Publisher: SinglePublisher {
            typealias Output = Int
            typealias Failure = TestError
            
            let witness: Witness
            
            func receive<S>(subscriber: S)
            where S: Subscriber, Failure == S.Failure, Output == S.Input
            {
                let subscription = Subscription(
                    downstream: subscriber,
                    context: witness)
                subscriber.receive(subscription: subscription)
            }
            
            private class Subscription<Downstream: Subscriber>:
                TraitSubscriptions.Single<Downstream, Witness>
            where
                Downstream.Input == Output,
                Downstream.Failure == Failure
            {
                override func start(with witness: Witness) {
                    witness.startCalled = true
                    receive(.success(1))
                }
                override func didCancel(with witness: Witness) {
                    witness.didCancelCalled = true
                }
                override func didComplete(with witness: Witness) {
                    witness.didCompleteCalled = true
                }
           }
        }
        
        let witness = Witness()
        let publisher = Publisher(witness: witness)
        
        var value: Int?
        var completion: Subscribers.Completion<TestError>?
        _ = publisher.sink(
            receiveCompletion: {
                completion = $0
            },
            receiveValue: {
                value = $0
            })

        XCTAssertEqual(value, 1)
        
        switch try XCTUnwrap(completion) {
        case .finished:
            break
        case let .failure(error):
            XCTFail("Unexpected error \(error)")
        }
        
        XCTAssertTrue(witness.startCalled)
        XCTAssertFalse(witness.didCancelCalled)
        XCTAssertTrue(witness.didCompleteCalled)
    }
    
    func test_completion_failure() throws {
        struct Publisher: SinglePublisher {
            typealias Output = Int
            typealias Failure = TestError
            
            let witness: Witness
            
            func receive<S>(subscriber: S)
            where S: Subscriber, Failure == S.Failure, Output == S.Input
            {
                let subscription = Subscription(
                    downstream: subscriber,
                    context: witness)
                subscriber.receive(subscription: subscription)
            }
            
            private class Subscription<Downstream: Subscriber>:
                TraitSubscriptions.Single<Downstream, Witness>
            where
                Downstream.Input == Output,
                Downstream.Failure == Failure
            {
                override func start(with witness: Witness) {
                    witness.startCalled = true
                    receive(.failure(TestError()))
                }
                override func didCancel(with witness: Witness) {
                    witness.didCancelCalled = true
                }
                override func didComplete(with witness: Witness) {
                    witness.didCompleteCalled = true
                }
           }
        }
        
        let witness = Witness()
        let publisher = Publisher(witness: witness)
        
        var value: Int?
        var completion: Subscribers.Completion<TestError>?
        _ = publisher.sink(
            receiveCompletion: {
                completion = $0
            },
            receiveValue: {
                value = $0
            })

        XCTAssertNil(value)
        
        switch try XCTUnwrap(completion) {
        case .finished:
            XCTFail("Unexpected success")
        case .failure:
            break
        }
        
        XCTAssertTrue(witness.startCalled)
        XCTAssertFalse(witness.didCancelCalled)
        XCTAssertTrue(witness.didCompleteCalled)
    }
    
    func test_cancellation() throws {
        struct Publisher: SinglePublisher {
            typealias Output = Int
            typealias Failure = TestError
            
            let witness: Witness
            
            func receive<S>(subscriber: S)
            where S: Subscriber, Failure == S.Failure, Output == S.Input
            {
                let subscription = Subscription(
                    downstream: subscriber,
                    context: witness)
                subscriber.receive(subscription: subscription)
            }
            
            private class Subscription<Downstream: Subscriber>:
                TraitSubscriptions.Single<Downstream, Witness>
            where
                Downstream.Input == Output,
                Downstream.Failure == Failure
            {
                override func start(with witness: Witness) {
                    witness.startCalled = true
                }
                override func didCancel(with witness: Witness) {
                    witness.didCancelCalled = true
                }
                override func didComplete(with witness: Witness) {
                    witness.didCompleteCalled = true
                }
           }
        }
        
        let witness = Witness()
        let publisher = Publisher(witness: witness)
        
        var value: Int?
        var completion: Subscribers.Completion<TestError>?
        let cancellable = publisher.sink(
            receiveCompletion: {
                completion = $0
            },
            receiveValue: {
                value = $0
            })
        cancellable.cancel()

        XCTAssertNil(value)
        XCTAssertNil(completion)
        
        XCTAssertTrue(witness.startCalled)
        XCTAssertTrue(witness.didCancelCalled)
        XCTAssertFalse(witness.didCompleteCalled)
    }
}
