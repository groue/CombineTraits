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
///         Just(1).append(Fail(error)).uncheckedSingle()
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
///         // Publishes one value, and then completes.
///         AnySinglePublisher.just(value)
///
///         // Fails with the given error.
///         AnySinglePublisher.fail(error)
///
///         // Never publishes any value, never completes.
///         AnySinglePublisher.never()
public protocol SinglePublisher: MaybePublisher { }

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
    ///
    /// - Parameters:
    ///   - prefix: A string used at the beginning of the fatal error message.
    ///   - file: A filename used in the error message. This defaults to `#file`.
    ///   - line: A line number used in the error message. This defaults to `#line`.
    /// - Returns: A publisher that raises a fatal error when its upstream publisher fails.
    public func assertSingle(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertSinglePublisher<Self> {
        checkSingle().assertNoSingleFailure(prefix, file: file, line: line)
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
    ///     Just(1).append(Fail(error)).uncheckedSingle()
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
public typealias AssertSinglePublisher<Upstream: Publisher>
    = Publishers.MapError<CheckSinglePublisher<Upstream>, Upstream.Failure>

extension SinglePublisher {
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher")
    func checkSingle() -> CheckSinglePublisher<Self> {
        CheckSinglePublisher(upstream: self)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher")
    public func assertSingle(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertSinglePublisher<Self> {
        checkSingle().assertNoSingleFailure(prefix, file: file, line: line)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a single publisher: use publisher.eraseToAnySinglePublisher() instead.")
    public func uncheckedSingle() -> AnySinglePublisher<Output, Failure> {
        AnySinglePublisher(self)
    }
}

/// The error for checked single publishers returned
/// from `Publisher.eraseToAnySinglePublisher()`.
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

extension SinglePublisher where Failure: _SingleError {
    /// Raises a fatal error when the upstream publisher fails with a violation
    /// of the `SinglePublisher` contract, and otherwise republishes all
    /// received input.
    fileprivate func assertNoSingleFailure(_ prefix: String, file: StaticString, line: UInt)
    -> Publishers.MapError<Self, Failure.UpstreamFailure>
    {
        mapError { error in
            error.assertUpstreamFailure(prefix, file: file, line: line)
        }
    }
}

protocol _SingleError {
    associatedtype UpstreamFailure: Error
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure
}

extension SingleError: _SingleError {
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure {
        switch self {
        case .missingElement:
            fatalError([prefix, "Single violation: missing element at \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
        case .tooManyElements:
            fatalError([prefix, "Single violation: too many elements at \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
        case .bothElementAndError:
            fatalError([prefix, "Single violation: error completion after one element was published \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
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

extension AnySinglePublisher where Failure == Never {
    /// Creates an `AnySinglePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output) -> Self {
        Just(value).eraseToAnySinglePublisher()
    }
}

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

extension Publishers.AllSatisfy: SinglePublisher { }

extension Publishers.AssertNoFailure: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Autoconnect: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Breakpoint: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Catch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.CombineLatest: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

extension Publishers.CombineLatest3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

extension Publishers.CombineLatest4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

extension Publishers.Contains: SinglePublisher { }

extension Publishers.ContainsWhere: SinglePublisher { }

extension Publishers.Count: SinglePublisher { }

extension Publishers.Delay: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.FlatMap: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.HandleEvents: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MakeConnectable: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Map: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapError: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath2: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath3: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Print: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.ReceiveOn: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.ReplaceEmpty: SinglePublisher
where Upstream: MaybePublisher { }

extension Publishers.ReplaceError: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Retry: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SetFailureType: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SubscribeOn: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SwitchToLatest: SinglePublisher
where Upstream: SinglePublisher, P: SinglePublisher { }

extension Publishers.TryAllSatisfy: SinglePublisher { }

extension Publishers.TryCatch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.TryContainsWhere: SinglePublisher { }

extension Publishers.TryMap: SinglePublisher
where Upstream: SinglePublisher { }

// We can't declare "OR" conformance (Zip is a maybe if A or B is a maybe)
extension Publishers.Zip: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

// We can't declare "OR" conformance (Zip3 is a maybe if A or B or C is a maybe)
extension Publishers.Zip3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

// We can't declare "OR" conformance (Zip4 is a maybe if A or B or C or D is a maybe)
extension Publishers.Zip4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

extension Result.Publisher: SinglePublisher { }

extension URLSession.DataTaskPublisher: SinglePublisher { }

extension Deferred: SinglePublisher
where DeferredPublisher: SinglePublisher { }

extension Fail: SinglePublisher { }

extension Future: SinglePublisher { }

extension Just: SinglePublisher { }
