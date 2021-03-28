import Foundation

/// To create an operation:
///
/// 1. Subclass AsynchronousOperation, override main, and eventually cancel the
///    operation, or set result to a non-nil value.
///
/// 2. Use makeOperation { op in ... }, and eventually cancel the
///    operation, or set result to a non-nil value.
open class AsynchronousOperation<Output, Failure: Error>: Operation {
    /// Setting the result to a non-nil value finishes the operation.
    ///
    /// If operation is already finished, setting the result has no effect.
    public var result: Result<Output, Failure>? {
        get { return _result }
        set {
            synchronized {
                if _isFinished { return }
                if _isEarlyFinished { return }

                if _isExecuting {
                    willChangeValue(forKey: isExecutingKey)
                    willChangeValue(forKey: isFinishedKey)
                    _isExecuting = false
                    _result = newValue
                    _isFinished = true
                    didChangeValue(forKey: isFinishedKey)
                    didChangeValue(forKey: isExecutingKey)
                } else {
                    _isEarlyFinished = true
                    _result = newValue
                }
                
                didComplete()
            }
        }
    }
    
    override open func cancel() {
        synchronized {
            if _isFinished { return }
            if _isEarlyFinished { return }
            
            if _isCancelled == false {
                willChangeValue(forKey: isCancelledKey)
                _isCancelled = true
                didChangeValue(forKey: isCancelledKey)
            }
            
            if _isExecuting {
                super.cancel()
                willChangeValue(forKey: isExecutingKey)
                willChangeValue(forKey: isFinishedKey)
                _isExecuting = false
                _isFinished = true
                didChangeValue(forKey: isFinishedKey)
                didChangeValue(forKey: isExecutingKey)
            } else {
                _isEarlyFinished = true
            }
            
            didComplete()
        }
    }
    
    /// Updates the `completionBlock` of the operation so that it performs the
    /// provided result handler.
    ///
    /// The result handler is executed when the operation completes
    /// successfully, completes with an error, or is cancelled.
    ///
    /// The result handler is executed on the specified dispatch queue, which
    /// defaults to `DispatchQueue.main`. When the queue is nil, the result
    /// handler is executed right within the operation's `completionBlock`.
    ///
    /// The result handler can refer to the operation without preventing the
    /// operation to deallocate after completion.
    ///
    /// - parameter queue: The `DispatchQueue` which runs the result handler.
    ///   When the queue is nil, the completion block is executed right within
    ///   the operation's `completionBlock`.
    /// - parameter resultHandler: A function that runs when the operation
    ///   is finished.
    /// - parameter result: The result of the operation. If nil, the
    ///   operation was cancelled.
    public func handleCompletion(
        onQueue queue: DispatchQueue? = DispatchQueue.main,
        result resultHandler: @escaping (_ result: Result<Output, Failure>?) -> Void)
    {
        completionBlock = { [unowned self] in
            let result = self.result
            assert(result != nil || self.isCancelled)
            if let queue = queue {
                queue.async {
                    resultHandler(result)
                }
            } else {
                resultHandler(result)
            }
        }
    }
    
    public static func blockOperation(
        _ block: @escaping (AsynchronousOperation<Output, Failure>) -> Void)
    -> AsynchronousOperation<Output, Failure>
    {
        return AsynchronousBlockOperation(block)
    }
    
    /// Don't override. Override main() instead.
    override public func start() {
        synchronized {
            if _isEarlyFinished {
                willChangeValue(forKey: isFinishedKey)
                _isFinished = true
                didChangeValue(forKey: isFinishedKey)
            } else {
                willChangeValue(forKey: isExecutingKey)
                _isExecuting = true
                didChangeValue(forKey: isExecutingKey)
                main()
            }
        }
    }
    
    /// Called after the result has been set, or operation was cancelled.
    ///
    /// Subclasses can override this method. Default implementation
    /// does nothing.
    ///
    /// - warning: Don't assume the `isFinished` flag is set, because
    /// an asynchronous operation may get a result, or be cancelled, before it
    /// is scheduled in an operation queue.
    open func didComplete() { }
    
    override public var isAsynchronous: Bool { return true }
    override public var isExecuting: Bool { return _isExecuting }
    override public var isFinished: Bool { return _isFinished }
    override public var isCancelled: Bool { return _isCancelled }
    
    private var _result: Result<Output, Failure>? = nil
    private var lock = NSRecursiveLock()
    
    private var _isCancelled = false
    private var _isExecuting = false
    private var _isFinished = false
    
    /// Set to true whenever the operation is completed before the operation
    /// queue has called the start() method, and the operation has become
    /// "executing". We have to wait until start() is called before we trigger
    /// the "isFinished" KVO notifications, or we get warnings in the console,
    /// and even hard crashes.
    private var _isEarlyFinished = false
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
}

private let isCancelledKey = "isCancelled"
private let isExecutingKey = "isExecuting"
private let isFinishedKey = "isFinished"

private class AsynchronousBlockOperation<Output, Failure: Error>: AsynchronousOperation<Output, Failure> {
    let block: (AsynchronousOperation<Output, Failure>) -> Void
    
    init(_ block: @escaping (AsynchronousOperation<Output, Failure>) -> Void) {
        self.block = block
    }
    
    override func main() {
        block(self)
    }
}

extension OperationQueue {
    public convenience init(
        name: String? = nil,
        qualityOfService: QualityOfService,
        maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount)
    {
        self.init()
        self.name = name
        self.qualityOfService = qualityOfService
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
}
