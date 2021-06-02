import AsynchronousOperation
import Combine
import Foundation

extension SinglePublisher {
    /// Creates an asynchronous operation that wraps the upstream publisher.
    ///
    /// The uptream publisher is subscribed when the operation starts. The
    /// operation completes when the uptream publisher completes.
    ///
    /// Use `subscribe(on:options:)` when you need to control when the upstream
    /// publisher is subscribed:
    ///
    ///     let operation = upstreamPublisher
    ///         .subscribe(on: DispatchQueue.main)
    ///         .operation()
    public func makeOperation() -> SinglePublisherOperation<Self> {
        SinglePublisherOperation(self)
    }
    
    /// When it is subscribed, the returned publisher creates and schedules a
    /// new Operation in `operationQueue`. The subscription completes with the
    /// operation, when the `uptream` publisher completes.
    ///
    /// Use `subscribe(on:options:)` when you need to control when the upstream
    /// publisher is subscribed:
    ///
    ///     let publisher = upstreamPublisher
    ///         .subscribe(on: DispatchQueue.main)
    ///         .asOperation(in: queue)
    ///
    /// Use `receive(on:options:)` when you need to control when the returned
    /// publisher publishes its element and completion:
    ///
    ///     let publisher = upstreamPublisher
    ///         .asOperation(in: queue)
    ///         .receive(on: DispatchQueue.main)
    ///
    /// - parameter operationQueue: The `OperationQueue` to run the publisher in.
    /// - parameter queuePriority: The execution priority of the operation.
    ///   Defaults to `.normal`.
    public func asOperation(
        in operationQueue: OperationQueue,
        queuePriority: Operation.QueuePriority = .normal)
    -> TraitPublishers.AsOperation<Self>
    {
        TraitPublishers.AsOperation(
            upstream: self,
            operationQueue: operationQueue,
            queuePriority: queuePriority)
    }
}

/// An operation that subscribe to a single publisher.
public class SinglePublisherOperation<Upstream: SinglePublisher>: AsynchronousOperation<Upstream.Output, Upstream.Failure> {
    private var upstream: Upstream?
    private var cancellable: AnyCancellable?
    
    fileprivate init(_ upstream: Upstream) {
        self.upstream = upstream
    }
    
    override public func main() {
        guard let upstream = upstream else {
            // It can only get nil if operation was cancelled. Who would
            // call main() on a cancelled operation? Nobody.
            preconditionFailure("Operation started without upstream publisher")
        }
        
        cancellable = upstream.sinkSingle { [weak self] result in
            self?.finish(with: result)
        }
        
        // Release memory
        self.upstream = nil
    }
    
    override public func cancel() {
        super.cancel()
        upstream = nil
        cancellable = nil
    }
}

extension TraitPublishers {
    /// `AsOperation` is a publisher that wraps the upstream single publisher in
    /// a Foundation Operation.
    public struct AsOperation<Upstream: SinglePublisher>: SinglePublisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        public let operationQueue: OperationQueue
        public let queuePriority: Operation.QueuePriority
        
        private struct Context {
            let upstream: Upstream
            let operationQueue: OperationQueue
            let queuePriority: Operation.QueuePriority
        }
        
        /// When it is subscribed, `AsOperation` creates and schedules a new
        /// Operation in `operationQueue`. The subscription completes with the
        /// operation, when the uptream publisher completes.
        ///
        /// - parameter upstream: The upstream publisher.
        /// - parameter operationQueue: The `OperationQueue` to run the
        ///   publisher in.
        public init(
            upstream: Upstream,
            operationQueue: OperationQueue,
            queuePriority: Operation.QueuePriority)
        {
            self.upstream = upstream
            self.operationQueue = operationQueue
            self.queuePriority = queuePriority
        }
        
        public func receive<S>(subscriber: S)
        where S: Subscriber, S.Failure == Self.Failure, S.Input == Self.Output
        {
            let subscription = Subscription(
                downstream: subscriber,
                context: Context(upstream: upstream, operationQueue: operationQueue, queuePriority: queuePriority))
            subscriber.receive(subscription: subscription)
        }
        
        private class Subscription<Downstream: Subscriber>:
            TraitSubscriptions.Single<Downstream, Context>
        where
            Downstream.Input == Output,
            Downstream.Failure == Failure
        {
            private weak var operation: SinglePublisherOperation<Upstream>?
            
            override func start(with context: Context) {
                let operation = context.upstream.makeOperation()
                operation.queuePriority = context.queuePriority
                operation.handleCompletion(onQueue: nil) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case nil:
                        self.cancel()
                    case let .success(value):
                        self.receive(.success(value))
                    case let .failure(error):
                        self.receive(.failure(error))
                    }
                }
                self.operation = operation
                context.operationQueue.addOperation(operation)
            }
            
            override func didCancel(with context: Context) {
                operation?.cancel()
            }
        }
    }
}
