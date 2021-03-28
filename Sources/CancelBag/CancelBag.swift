import Combine
import Foundation

/// A thread-safe store for cancellables which addresses usability pain points
/// with stock Combine apis.
///
/// `CancelBag` cancels its cancellables when it is deinitialized.
///
/// ## Thread-safe storage of cancellables
///
/// You can store a cancellable in `CancelBag` from any thread.
///
/// ## Memory consumption
///
/// When you want to retain a cancellable until it the subscription completes or
/// gets cancelled, use the `sink(in:)` method:
///
///     // Releases memory when subscription completes or is cancelled.
///     publisher.sink(
///         in: cancellables,
///         receiveCompletion: ...
///         receiveValue: ...)
///
///     // Manual cancellation is still possible
///     let cancellable = publisher.sink(
///         in: cancellables,
///         receiveCompletion: ...
///         receiveValue: ...)
///     cancellable.cancel()
public final class CancelBag {
    private var lock = NSRecursiveLock() // Allow reentrancy
    private var cancellables: [AnyCancellable] = []
    
    /// Returns whether the CancelBag contains cancellables or not.
    public var isEmpty: Bool { synchronized { cancellables.isEmpty } }

    /// Creates an empty `CancelBag`.
    public init() { }
    
    deinit {
        cancel()
    }
    
    func remove(_ cancellable: AnyCancellable) {
        synchronized {
            if let index = cancellables.firstIndex(where: { $0 === cancellable }) {
                cancellables.remove(at: index)
            }
        }
    }
    
    fileprivate func store<T: Cancellable>(_ cancellable: T) {
        synchronized {
            if let any = cancellable as? AnyCancellable {
                // Don't lose cancellable identity, so that we can remove it.
                cancellables.append(any)
            } else {
                cancellable.store(in: &cancellables)
            }
        }
    }
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
}

extension CancelBag: Cancellable {
    public func cancel() {
        synchronized {
            // Avoid exclusive access violation: each cancellable may trigger a
            // call to remove(_:), and mutate self.cancellables
            let cancellables = self.cancellables
            for cancellable in cancellables {
                cancellable.cancel()
            }
            // OK, they are all cancelled now
            self.cancellables = []
        }
    }
}

extension Cancellable {
    public func store(in bag: CancelBag) {
        bag.store(self)
    }
}

extension Publisher {
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited
    /// number of values.
    ///
    /// The returned cancellable is added to `cancellables`, and removed when
    /// the subscription completes.
    ///
    /// - parameter cancellables: A CancelBag instance.
    /// - parameter receiveComplete: The closure to execute on completion.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - returns: An AnyCancellable instance.
    @discardableResult
    public func sink(
        in cancellables: CancelBag,
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void)
        -> AnyCancellable
    {
        var cancellable: AnyCancellable?
        // Prevents a retain cycle when cancellable retains itself
        var unmanagedCancellable: Unmanaged<AnyCancellable>?
        
        cancellable = self
            .handleEvents(
                receiveCancel: { [weak cancellables] in
                    // Postpone cleanup in case subscription finishes
                    // before cancellable is set.
                    if let unmanagedCancellable = unmanagedCancellable {
                        cancellables?.remove(unmanagedCancellable.takeUnretainedValue())
                        unmanagedCancellable.release()
                    } else {
                        DispatchQueue.main.async {
                            if let unmanagedCancellable = unmanagedCancellable {
                                cancellables?.remove(unmanagedCancellable.takeUnretainedValue())
                                unmanagedCancellable.release()
                            }
                        }
                    }
            })
            .sink(
                receiveCompletion: { [weak cancellables] completion in
                    receiveCompletion(completion)
                    // Postpone cleanup in case subscription finishes
                    // before cancellable is set.
                    if let unmanagedCancellable = unmanagedCancellable {
                        cancellables?.remove(unmanagedCancellable.takeUnretainedValue())
                        unmanagedCancellable.release()
                    } else {
                        DispatchQueue.main.async {
                            if let unmanagedCancellable = unmanagedCancellable {
                                cancellables?.remove(unmanagedCancellable.takeUnretainedValue())
                                unmanagedCancellable.release()
                            }
                        }
                    }
                },
                receiveValue: receiveValue)
        
        unmanagedCancellable = Unmanaged.passRetained(cancellable!)
        cancellable!.store(in: cancellables)
        return cancellable!
    }
}

extension Publisher where Failure == Never {
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited
    /// number of values.
    ///
    /// The returned cancellable is added to `cancellables`, and removed when
    /// the subscription completes.
    ///
    /// - parameter cancellables: A CancelBag instance.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - returns: An AnyCancellable instance.
    @discardableResult
    public func sink(
        in cancellables: CancelBag,
        receiveValue: @escaping (Output) -> Void)
        -> AnyCancellable
    {
        sink(in: cancellables, receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
}
