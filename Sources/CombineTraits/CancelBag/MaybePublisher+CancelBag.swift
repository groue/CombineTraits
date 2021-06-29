#if !COCOAPODS
    import CancelBag
#endif

import Combine
import Foundation

extension MaybePublisher {
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited
    /// number of values.
    ///
    /// The returned cancellable is added to `cancellables`, and removed when
    /// the subscription completes.
    ///
    /// - parameter cancellables: A CancelBag instance.
    /// - parameter receive: The closure to execute on completion.
    /// - returns: An AnyCancellable instance.
    @discardableResult
    public func sinkMaybe(
        in cancellables: CancelBag,
        receive: @escaping (MaybeResult<Output, Failure>) -> Void)
        -> AnyCancellable
    {
        // Assume value and completion can be received concurrently.
        let lock = NSRecursiveLock()
        var successReceived = false // protected by lock
        return sink(
            in: cancellables,
            receiveCompletion: { completion in
                lock.lock()
                defer { lock.unlock() }
                switch completion {
                case let .failure(error):
                    receive(.failure(error))
                case .finished:
                    if !successReceived {
                        receive(.finished)
                    }
                }
            },
            receiveValue: { value in
                lock.lock()
                defer { lock.unlock() }
                successReceived = true
                receive(.success(value))
            })
    }
}
