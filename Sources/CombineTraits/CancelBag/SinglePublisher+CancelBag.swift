#if !COCOAPODS
    import CancelBag
#endif

import Combine
import Foundation

extension SinglePublisher {
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
    public func sinkSingle(
        in cancellables: CancelBag,
        receive: @escaping (Result<Output, Failure>) -> Void)
        -> AnyCancellable
    {
        sink(
            in: cancellables,
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    receive(.failure(error))
                }
            },
            receiveValue: { value in
                receive(.success(value))
            })
    }
}
