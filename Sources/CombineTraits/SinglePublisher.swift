import Combine
import Foundation

// MARK: - SinglePublisher

/// `SinglePublisher` is the protocol for publishers that publish exactly one
/// element, or an error.
///
/// In the Combine framework, the built-in `Just`, `Future` and
/// `URLSession.DataTaskPublisher` are examples of publishers that conform
/// to `SinglePublisher`.
///
/// Conversely, `Publishers.Sequence` is not a single publisher, because not all
/// sequences contain a single element.
///
/// # SinglePublisher Benefits
///
/// Once you have a publisher that conforms to `SinglePublisher`, you have
/// access to two desirable tools:
///
/// - An `AnySinglePublisher` type that hides details you don’t want to expose
///   across API boundaries. For example, the user of the publisher below knows
///   that it publishes exactly one `String`, no more, no less:
///
///         func namePublisher() -> AnySinglePublisher<String, Error>
///
///   You build an `AnySinglePublisher` with the
///   `eraseToAnySinglePublisher()` method:
///
///         mySinglePublisher.eraseToAnySinglePublisher()
///
/// - A `sinkSingle(receive:)` method that simplifies handling of single
///   publisher results:
///
///         namePublisher().sinkSingle { result in
///             switch result {
///                 case let .success(name): print(name)
///                 case let .failure(error): print(error)
///             }
///         }
///
/// # Building Single Publishers
///
/// In order to benefit from the `SinglePublisher` protocol, you need a concrete
/// publisher that conforms to this protocol.
///
/// There are a few ways to get such a single publisher:
///
/// - **Compiler-checked single publishers** are publishers that conform to the
///   `SinglePublisher` protocol. This is the case of `Just` and `Fail`, for
///   example. Some publishers conditionally conform to `SinglePublisher`, such
///   as `Publishers.Map`, when the upstream publisher is a single publisher.
///
///   When you define a publisher type that publishes exactly one element, or
///   an error, you can turn it into a single publisher with an extension:
///
///         struct MySinglePublisher: Publisher { ... }
///         extension MySinglePublisher: SinglePublisher { }
///
/// - **Runtime-checked single publishers** are publishers that conform to the
///   `SinglePublisher` protocol by checking, at runtime, that an upstream
///   publisher publishes exactly one element, or an error.
///
///   You build a checked single publisher with one of those methods:
///
///     - `Publisher.checkSingle()` returns a single publisher that fails with a
///       `SingleError` if the upstream publisher does not publish exactly one
///       element, or an error.
///
///     - `Publisher.assertSingle()` returns a single publisher that raises a
///       fatal error if the upstream publisher does not publish exactly one
///       element, or an error.
///
/// - **Unchecked single publishers**: you should only build such a single
///   publisher when you are sure that the `SinglePublisher` contract
///   is honored by the upstream publisher.
///
///   For example:
///
///         // CORRECT: those publish exactly one element, or an error.
///         [1].publisher.uncheckedSingle()
///         [1, 2].publisher.prefix(1).uncheckedSingle()
///
///         // WRONG: does not publish any element
///         Empty().uncheckedSingle()
///
///         // WRONG: publishes more than one element
///         [1, 2].publisher.uncheckedSingle()
///
///         // WRONG: does not publish exactly one element, or an error
///         Just(1).append(Fail(error))
///
///         // WARNING: may not publish exactly one element, or an error
///         someSubject.prefix(1).uncheckedSingle()
///
///   The consequences of using `uncheckedSingle()` on a publisher that does not
///   publish exactly one element, or an error, are undefined.
///
/// # Basic Single Publishers
///
/// `AnySinglePublisher` comes with factory methods that build basic
/// single publishers:
///
///         // Immediately publishes one value, and then completes.
///         AnySinglePublisher.just(value)
///
///         // Immediately fails with the given error.
///         AnySinglePublisher.fail(error)
///
///         // Never publishes any value, never completes.
///         AnySinglePublisher.never()
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol SinglePublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SinglePublisher {
    /// Wraps this single publisher with a type eraser.
    ///
    /// Use `eraseToAnySinglePublisher()` to expose an instance of
    /// AnySinglePublisher to the downstream subscriber, rather than this
    /// publisher’s actual type.
    ///
    /// This form of type erasure preserves abstraction across API boundaries,
    /// such as different modules. When you expose your publishers as the
    /// AnySinglePublisher type, you can change the underlying implementation
    /// over time without affecting existing clients.
    ///
    /// - returns: An `AnySinglePublisher` wrapping this single publisher.
    public func eraseToAnySinglePublisher() -> AnySinglePublisher<Output, Failure> {
        AnySinglePublisher(self)
    }
    
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited
    /// number of values, prior to returning the subscriber.
    ///
    /// - parameter receive: The closure to execute when the single
    ///   publisher completes, with one value, or an error.
    /// - returns: A cancellable.
    public func sinkSingle(receive: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        sink(
            receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    receive(.failure(error))
                case .finished:
                    break
                }
            },
            receiveValue: { value in
                receive(.success(value))
            })
    }
}

// MARK: - Checked & Unchecked Single Publishers

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    /// Checks that the publisher publishes exactly one element, or an error,
    /// and turns contract violations into a `SingleError`.
    ///
    /// See also `Publisher.assertSingle()`.
    public func checkSingle() -> CheckSinglePublisher<Self> {
        CheckSinglePublisher(upstream: self)
    }
    
    /// Checks that the publisher publishes exactly one element, or an error,
    /// and raises a fatal error if the contract is not honored.
    ///
    /// See also `Publisher.checkSingle()`.
    public func assertSingle() -> AssertSinglePublisher<Self> {
        checkSingle().assertNoSingleFailure()
    }
    
    /// Turns a publisher into a single publisher, assuming that it publishes
    /// exactly one element, or an error.
    ///
    /// For example:
    ///
    ///     // CORRECT: those publish exactly one element, or an error.
    ///     [1].publisher.uncheckedSingle()
    ///     [1, 2].publisher.prefix(1).uncheckedSingle()
    ///
    ///     // WRONG: does not publish any element
    ///     Empty().uncheckedSingle()
    ///
    ///     // WRONG: publishes more than one element
    ///     [1, 2].publisher.uncheckedSingle()
    ///
    ///     // WRONG: does not publish exactly one element, or an error
    ///     Just(1).append(Fail(error))
    ///
    ///     // WARNING: may not publish exactly one element, or an error
    ///     someSubject.prefix(1).uncheckedSingle()
    ///
    /// See also `Publisher.assertSingle()`.
    ///
    /// - warning: Violation of the single publisher contract are not checked.
    public func uncheckedSingle() -> AnySinglePublisher<Output, Failure> {
        AnySinglePublisher(unchecked: self)
    }
}

/// The type of publishers returned by `Publisher.assertSingle()`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias AssertSinglePublisher<Upstream: Publisher>
    = Publishers.MapError<CheckSinglePublisher<Upstream>, Upstream.Failure>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SinglePublisher {
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher")
    func checkSingle() -> CheckSinglePublisher<Self> {
        CheckSinglePublisher(upstream: self)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher")
    public func assertSingle() -> AssertSinglePublisher<Self> {
        checkSingle().assertNoSingleFailure()
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher: use publisher.eraseToAnySinglePublisher() instead.")
    public func uncheckedSingle() -> AnySinglePublisher<Output, Failure> {
        AnySinglePublisher(self)
    }
}

/// The error for checked single publishers returned
/// from `Publisher.eraseToAnySinglePublisher()`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum SingleError<UpstreamFailure: Error>: Error {
    /// Upstream publisher did complete without publishing any element
    case missingElement
    
    /// Upstream publisher did publish more than one element
    case tooManyElements
    
    /// Upstream publisher did complete with an error after publishing one element
    case bothElementAndError
    
    /// Upstream publisher did complete with an error
    case upstream(UpstreamFailure)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SinglePublisher where Failure: _SingleError {
    /// Raises a fatal error when the upstream publisher fails with a violation
    /// of the `SinglePublisher` contract, and otherwise republishes all
    /// received input.
    func assertNoSingleFailure(file: StaticString = #file, line: UInt = #line)
    -> Publishers.MapError<Self, Failure.UpstreamFailure>
    {
        mapError { error in
            error.assertUpstreamFailure(file: file, line: line)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
protocol _SingleError {
    associatedtype UpstreamFailure: Error
    func assertUpstreamFailure(file: StaticString, line: UInt) -> UpstreamFailure
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SingleError: _SingleError {
    func assertUpstreamFailure(file: StaticString, line: UInt) -> UpstreamFailure {
        switch self {
        case .missingElement:
            fatalError("Single violation: missing element at \(file):\(line)")
        case .tooManyElements:
            fatalError("Single violation: too many elements at \(file):\(line)")
        case .bothElementAndError:
            fatalError("Single violation: error completion after one element was published \(file):\(line)")
        case let .upstream(error):
            return error
        }
    }
}

// MARK: - AnySinglePublisher

/// A publisher that performs type erasure by wrapping another single publisher.
///
/// `AnySinglePublisher` is a concrete implementation of `SinglePublisher` that
/// has no significant properties of its own, and passes through elements and
/// completion values from its upstream publisher.
///
/// Use `AnySinglePublisher` to wrap a publisher whose type has details you
/// don’t want to expose across API boundaries, such as different modules.
///
/// You can use `eraseToAnySinglePublisher()` operator to wrap a publisher
/// with `AnySinglePublisher`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AnySinglePublisher<Output, Failure: Error>: SinglePublisher {
    public typealias Failure = Failure
    fileprivate let upstream: AnyPublisher<Output, Failure>
    
    /// Creates a type-erasing publisher to wrap the unchecked single publisher.
    ///
    /// See `Publisher.uncheckedSingle()`.
    fileprivate init<P>(unchecked publisher: P)
    where P: Publisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the unchecked single publisher.
    ///
    /// See `Publisher.uncheckedSingle()`.
    @available(*, deprecated, message: "Publisher is already a single publisher: use AnySinglePublisher.init(_:) instead.")
    fileprivate init<P>(unchecked publisher: P)
    where P: SinglePublisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the provided single publisher.
    ///
    /// See `SinglePublisher.eraseToAnyPublisher()`.
    public init<P>(_ singlePublisher: P)
    where P: SinglePublisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = singlePublisher.eraseToAnyPublisher()
    }
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Self.Failure, S.Input == Output
    {
        upstream.receive(subscriber: subscriber)
    }
}

// MARK: - Canonical Single Publishers

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AnySinglePublisher where Failure == Never {
    /// Creates an `AnySinglePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output) -> Self {
        Just(value).eraseToAnySinglePublisher()
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AnySinglePublisher {
    /// Creates an `AnySinglePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output, failureType: Failure.Type = Self.Failure) -> Self {
        Just(value)
            .setFailureType(to: failureType)
            .eraseToAnySinglePublisher()
    }
    
    /// Creates an `AnySinglePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure) -> Self {
        Fail(error: error).eraseToAnySinglePublisher()
    }
    
    /// Creates an `AnySinglePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure, outputType: Output.Type) -> Self {
        Fail(outputType: outputType, failure: error).eraseToAnySinglePublisher()
    }
    
    /// Creates an `AnySinglePublisher` which never completes.
    public static func never() -> Self {
        Empty(completeImmediately: false).uncheckedSingle()
    }
    
    /// Creates an `AnySinglePublisher` which never completes.
    public static func never(outputType: Output.Type, failureType: Failure.Type) -> Self {
        Empty(completeImmediately: false, outputType: outputType, failureType: failureType).uncheckedSingle()
    }
}

// MARK: - CheckSinglePublisher

/// A single publisher that checks that another publisher publishes exactly one
/// element, or an error.
///
/// `CheckSinglePublisher` can fail with a `SingleError`:
///
/// - `.missingElement`: Upstream publisher did complete without publishing
///   any element.
///
/// - `.tooManyElements`: Upstream publisher did publish more than one element.
///
/// - `.bothElementAndError`: Upstream publisher did publish one element and
///   then an error.
///
/// - `.upstream(error)`: Upstream publisher did complete with an error.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct CheckSinglePublisher<Upstream: Publisher>: SinglePublisher {
    public typealias Output = Upstream.Output
    public typealias Failure = SingleError<Upstream.Failure>
    
    let upstream: Upstream
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Self.Failure, S.Input == Output
    {
        let subscription = CheckSingleSubscription(
            upstream: upstream,
            downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private class CheckSingleSubscription<Upstream: Publisher, Downstream: Subscriber>: Subscription, Subscriber
where
    Downstream.Input == Upstream.Output,
    Downstream.Failure == SingleError<Upstream.Failure>
{
    private enum State {
        case waitingForRequest(Upstream, Downstream)
        case waitingForSubscription(Subscribers.Demand, Downstream)
        case waitingForElement(Subscription, Downstream)
        case waitingForCompletion(Upstream.Output, Subscription, Downstream)
        case finished
    }
    
    private var state: State
    private let lock = NSRecursiveLock()
    
    init(
        upstream: Upstream,
        downstream: Downstream)
    {
        self.state = .waitingForRequest(upstream, downstream)
    }
    
    // MARK: - Subscription
    
    func request(_ demand: Subscribers.Demand) {
        synchronized {
            switch state {
            case let .waitingForRequest(upstream, downstream):
                state = .waitingForSubscription(demand, downstream)
                upstream.receive(subscriber: self)
                
            case let .waitingForSubscription(currentDemand, downstream):
                state = .waitingForSubscription(demand + currentDemand, downstream)
                
            case let .waitingForElement(subscription, _):
                subscription.request(demand)
                
            case .waitingForCompletion, .finished:
                break
            }
        }
    }
    
    func cancel() {
        synchronized {
            switch state {
            case .waitingForRequest, .waitingForSubscription:
                state = .finished
                
            case let .waitingForElement(subcription, _),
                 let .waitingForCompletion(_, subcription, _):
                subcription.cancel()
                state = .finished
                
            case .finished:
                break
            }
        }
    }
    
    // MARK: - Subscriber
    
    func receive(subscription: Subscription) {
        synchronized {
            switch state {
            case let .waitingForSubscription(currentDemand, downstream):
                state = .waitingForElement(subscription, downstream)
                subscription.request(currentDemand)
                
            case .waitingForRequest, .waitingForElement, .waitingForCompletion, .finished:
                break
            }
        }
    }
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        synchronized {
            switch state {
            case let .waitingForElement(subscription, downstream):
                state = .waitingForCompletion(input, subscription, downstream)
                
            case let .waitingForCompletion(_, subscription, downstream):
                subscription.cancel()
                downstream.receive(completion: .failure(.tooManyElements))
                state = .finished
                
            case .waitingForRequest, .waitingForSubscription, .finished:
                break
            }
        }
        return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        synchronized {
            switch completion {
            case .finished:
                switch state {
                case let .waitingForRequest(_, downstream),
                     let .waitingForSubscription(_, downstream):
                    downstream.receive(completion: .failure(.missingElement))
                    state = .finished
                    
                case let .waitingForElement(subscription, downstream):
                    subscription.cancel()
                    downstream.receive(completion: .failure(.missingElement))
                    state = .finished
                    
                case let .waitingForCompletion(element, _, downstream):
                    _ = downstream.receive(element)
                    downstream.receive(completion: .finished)
                    state = .finished
                    
                case .finished:
                    break
                }
            case let .failure(error):
                switch state {
                case let .waitingForRequest(_, downstream),
                     let .waitingForSubscription(_, downstream):
                    downstream.receive(completion: .failure(.upstream(error)))
                    state = .finished
                    
                case let .waitingForElement(_, downstream):
                    downstream.receive(completion: .failure(.upstream(error)))
                    state = .finished
                    
                case let .waitingForCompletion(_, _, downstream):
                    downstream.receive(completion: .failure(.bothElementAndError))
                    state = .finished
                    
                case .finished:
                    break
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
}

// MARK: - Support

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.AllSatisfy: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.AssertNoFailure: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Autoconnect: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Breakpoint: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Catch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Contains: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.ContainsWhere: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Count: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Delay: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.FlatMap: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.HandleEvents: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MakeConnectable: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Map: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapError: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath2: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath3: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Print: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.ReceiveOn: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Retry: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SetFailureType: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SubscribeOn: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SwitchToLatest: SinglePublisher
where Upstream: SinglePublisher, P: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryAllSatisfy: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryCatch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryContainsWhere: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryMap: SinglePublisher
where Upstream: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Deferred: SinglePublisher
where DeferredPublisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Result.Publisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLSession.DataTaskPublisher: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Fail: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Future: SinglePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Just: SinglePublisher { }
