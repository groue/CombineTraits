import Combine
import CombineTraits
import XCTest

class MaybeSubscriptionTests: XCTestCase {
    func test_canonical_subclass_compiles() {
        // Here we just test that the documented way to subclass compiles
        typealias MyOutput = Int
        struct MyFailure: Error { }
        struct MyContext { }
        
        struct MyMaybePublisher: MaybePublisher {
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
                MaybeSubscription<Downstream, MyContext>
            where Downstream.Input == Output, Downstream.Failure == Failure
            {
                override func start(with context: MyContext) {
                    receive(.failure(MyFailure()))
                }
                
                override func didCancel(with context: MyContext) { }
            }
        }
    }
}
