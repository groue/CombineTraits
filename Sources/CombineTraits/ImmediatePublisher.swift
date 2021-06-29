import Combine
import Foundation

/// `ImmediatePublisher` is the protocol for publishers that publish an element
/// or fail right on subscription, synchronously, without any delay.
///
/// In the Combine framework, the built-in `Just` and `Fail` are examples of
/// publishers that conform to `ImmediatePublisher`.
///
/// Conversely, `Publishers.Sequence` is not an immediate publisher, because not
/// all sequences contain at least one element. `URLSession.DataTaskPublisher`
/// is not an immediate publisher, because it is asynchronous.
///
/// # ImmediatePublisher Benefits
///
/// Once you have a publisher that conforms to `ImmediatePublisher`, you have
/// access to two desirable tools:
///
/// - An `AnyImmediatePublisher` type that hides details you don’t want to
///   expose across API boundaries. For example, the user of the publisher below
///   knows that it publishes a first `String` immediately:
///
///         func namePublisher() -> AnyImmediatePublisher<String, Never>
///
///   You build an `AnyImmediatePublisher` with the
///   `eraseToAnyImmediatePublisher()` method:
///
///         myImmediatePublisher.eraseToAnyImmediatePublisher()
///
/// # Building Immediate Publishers
///
/// In order to benefit from the `ImmediatePublisher` protocol, you need a
/// concrete publisher that conforms to this protocol.
///
/// There are a few ways to get such an immediate publisher:
///
/// - **Compiler-checked immediate publishers** are publishers that conform to
///   the `ImmediatePublisher` protocol. This is the case of `Just`, for
///   example. Some publishers conditionally conform to `ImmediatePublisher`,
///   such as `Publishers.Map`, when the upstream publisher is an
///   immediate publisher.
///
///   When you define a publisher type that publishes an element or fails right
///   on subscription, you can turn it into an immediate publisher with
///   an extension:
///
///         struct MyImmediatePublisher: Publisher { ... }
///         extension MyImmediatePublisher: ImmediatePublisher { }
///
/// - **Runtime-checked immediate publishers** are publishers that conform to
///   the `ImmediatePublisher` protocol by checking, at runtime, that an
///   upstream publisher publishes an element or fails right on subscription.
///
///     `Publisher.assertImmediate()` returns an immediate publisher that raises
///     a fatal error if the upstream publisher does not publish an element or
///     fail right on subscription.
///
/// - **Unchecked immediate publishers**: you should only build such an
///   immediate publisher when you are sure that the `ImmediatePublisher`
///   contract is honored by the upstream publisher.
///
///   For example:
///
///         // CORRECT
///         Just(1).uncheckedImmediate()
///
///         // WRONG
///         Empty().uncheckedImmediate()
///         Just(1).delay(...).uncheckedImmediate()
///
///   The consequences of using `uncheckedImmediate()` on a publisher that does
///   not publish an element or fails right on subscription are undefined.
///
/// # Basic Immediate Publishers
///
/// `AnyImmediatePublisher` comes with factory methods that build basic
/// immediatee publishers:
///
///         // Publishes one value, and then completes.
///         AnyImmediatePublisher.just(value)
///
///         // Fails with the given error.
///         AnyImmediatePublisher.fail(error)
public protocol ImmediatePublisher: Publisher { }

extension ImmediatePublisher {
    /// Wraps this immediate publisher with a type eraser.
    ///
    /// Use `eraseToAnyImmediatePublisher()` to expose an instance of
    /// `AnyImmediatePublisher` to the downstream subscriber, rather than this
    /// publisher’s actual type.
    ///
    /// This form of type erasure preserves abstraction across API boundaries,
    /// such as different modules. When you expose your publishers as the
    /// `AnyImmediatePublisher` type, you can change the underlying implementation
    /// over time without affecting existing clients.
    ///
    /// - returns: An `AnyImmediatePublisher` wrapping this immediate publisher.
    public func eraseToAnyImmediatePublisher() -> AnyImmediatePublisher<Output, Failure> {
        AnyImmediatePublisher(self)
    }
}

// MARK: - Checked & Unchecked Immediate Publishers

extension Publisher {
    /// Checks that the publisher publishes an element or fails right on
    /// subscription, and turns contract violations into a `ImmediateError`.
    ///
    /// See also `Publisher.assertImmediate()`.
    func checkImmediate() -> CheckImmediatePublisher<Self> {
        CheckImmediatePublisher(upstream: self)
    }
    
    /// Checks that the publisher publishes an element or fails right on
    /// subscription, and raises a fatal error if the contract is not honored.
    ///
    /// - Parameters:
    ///   - prefix: A string used at the beginning of the fatal error message.
    ///   - file: A filename used in the error message. This defaults to `#file`.
    ///   - line: A line number used in the error message. This defaults to `#line`.
    /// - Returns: A publisher that raises a fatal error when its upstream publisher fails.
    public func assertImmediate(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertImmediatePublisher<Self> {
        checkImmediate().assertNoImmediateFailure(prefix, file: file, line: line)
    }
    
    /// Turns a publisher into an immediate publisher, assuming that it
    /// publishes an element or fails right on subscription.
    ///
    /// For example:
    ///
    ///     // CORRECT
    ///     Just(1).uncheckedImmediate()
    ///
    ///     // WRONG
    ///     Empty().uncheckedImmediate()
    ///     Just(1).delay(...).uncheckedImmediate()
    ///
    /// See also `Publisher.assertImmediate()`.
    ///
    /// - warning: Violation of the immediate publisher contract are
    ///   not checked.
    public func uncheckedImmediate() -> AnyImmediatePublisher<Output, Failure> {
        AnyImmediatePublisher(unchecked: self)
    }
}

/// The type of publishers returned by `Publisher.assertImmediate()`.
public typealias AssertImmediatePublisher<Upstream: Publisher>
    = Publishers.MapError<CheckImmediatePublisher<Upstream>, Upstream.Failure>

extension ImmediatePublisher {
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already an immediate publisher")
    func checkImmediate() -> CheckImmediatePublisher<Self> {
        CheckImmediatePublisher(upstream: self)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already an immediate publisher")
    public func assertImmediate(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertImmediatePublisher<Self> {
        checkImmediate().assertNoImmediateFailure(prefix, file: file, line: line)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already an immediate publisher: use publisher.eraseToAnyImmediatePublisher() instead.")
    public func uncheckedImmediate() -> AnyImmediatePublisher<Output, Failure> {
        AnyImmediatePublisher(self)
    }
}

protocol _ImmediateError {
    associatedtype UpstreamFailure: Error
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure
}

/// The error for checked immediate publishers.
public enum ImmediateError<UpstreamFailure: Error>: Error, _ImmediateError {
    /// Upstream publisher did not publish an element or fail right
    /// on subscription
    case notImmediate
    
    /// Upstream publisher did complete with an error
    case upstream(UpstreamFailure)
    
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure {
        switch self {
        case .notImmediate:
            fatalError([prefix, "Immediate violation: did not publish an element or fail right on subscription, at \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
        case let .upstream(error):
            return error
        }
    }
}

extension ImmediatePublisher where Failure: _ImmediateError {
    /// Raises a fatal error when the upstream publisher fails with a violation
    /// of the `ImmediatePublisher` contract, and otherwise republishes all
    /// received input.
    fileprivate func assertNoImmediateFailure(_ prefix: String, file: StaticString, line: UInt)
    -> Publishers.MapError<Self, Failure.UpstreamFailure>
    {
        mapError { error in
            error.assertUpstreamFailure(prefix, file: file, line: line)
        }
    }
}

// MARK: - AnyImmediatePublisher

/// A publisher that performs type erasure by wrapping another
/// immediate publisher.
///
/// `AnyImmediatePublisher` is a concrete implementation of `ImmediatePublisher`
/// that has no significant properties of its own, and passes through elements
/// and completion values from its upstream publisher.
///
/// Use `AnyImmediatePublisher` to wrap a publisher whose type has details you
/// don’t want to expose across API boundaries, such as different modules.
///
/// You can use `eraseToAnyImmediatePublisher()` operator to wrap a publisher
/// with `AnyImmediatePublisher`.
public struct AnyImmediatePublisher<Output, Failure: Error>: ImmediatePublisher {
    public typealias Failure = Failure
    fileprivate let upstream: AnyPublisher<Output, Failure>
    
    /// Creates a type-erasing publisher to wrap the unchecked
    /// immediate publisher.
    ///
    /// See `Publisher.uncheckedImmediate()`.
    fileprivate init<P>(unchecked publisher: P)
    where P: Publisher, P.Failure == Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the unchecked
    /// immediate publisher.
    ///
    /// See `Publisher.uncheckedImmediate()`.
    @available(*, deprecated, message: "Publisher is already an immediate publisher: use AnyImmediatePublisher.init(_:) instead.")
    fileprivate init<P>(unchecked publisher: P)
    where P: ImmediatePublisher, P.Failure == Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the provided
    /// immediate publisher.
    ///
    /// See `ImmediatePublisher.eraseToAnyImmediatePublisher()`.
    public init<P>(_ immediatePublisher: P)
    where P: ImmediatePublisher, P.Failure == Failure, P.Output == Output
    {
        self.upstream = immediatePublisher.eraseToAnyPublisher()
    }
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Failure, S.Input == Output
    {
        upstream.receive(subscriber: subscriber)
    }
}

// MARK: - Canonical Immediate Publishers

extension AnyImmediatePublisher where Failure == Never {
    /// Creates an `AnyImmediatePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output) -> Self {
        Just(value).eraseToAnyImmediatePublisher()
    }
}

extension AnyImmediatePublisher {
    /// Creates an `AnyImmediatePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output, failureType: Failure.Type = Self.Failure) -> Self {
        Just(value)
            .setFailureType(to: failureType)
            .eraseToAnyImmediatePublisher()
    }
    
    /// Creates an `AnyImmediatePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure) -> Self {
        Fail(error: error).eraseToAnyImmediatePublisher()
    }
    
    /// Creates an `AnyImmediatePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure, outputType: Output.Type) -> Self {
        Fail(outputType: outputType, failure: error).eraseToAnyImmediatePublisher()
    }
}

// MARK: - CheckImmediatePublisher

/// An immediate publisher that checks that another publisher publishes an
/// element or fails right on subscription.
///
/// `CheckImmediatePublisher` can fail with a `ImmediateError`:
///
/// - `.notImmediate`: Upstream publisher did not publish an element or fail
///   right on subscription
///
/// - `.upstream(error)`: Upstream publisher did complete with an error.
public struct CheckImmediatePublisher<Upstream: Publisher>: ImmediatePublisher {
    public typealias Output = Upstream.Output
    public typealias Failure = ImmediateError<Upstream.Failure>
    
    let upstream: Upstream
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Failure, S.Input == Output
    {
        let subscription = CheckImmediateSubscription(
            upstream: upstream,
            downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class CheckImmediateSubscription<Upstream: Publisher, Downstream: Subscriber>: Subscription, Subscriber
where
    Downstream.Input == Upstream.Output,
    Downstream.Failure == ImmediateError<Upstream.Failure>
{
    private enum State {
        case waitingForRequest(Upstream, Downstream)
        case waitingForSubscription(Subscribers.Demand, Downstream)
        case waitingForElementOrFailure(Subscription, Downstream)
        case subscribed(Subscription, Downstream)
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
                switch state {
                case let .waitingForElementOrFailure(subscription, downstream):
                    state = .finished
                    subscription.cancel()
                    downstream.receive(completion: .failure(.notImmediate))
                case .waitingForRequest, .waitingForSubscription, .subscribed, .finished:
                    break
                }
                
            case let .waitingForSubscription(currentDemand, downstream):
                state = .waitingForSubscription(demand + currentDemand, downstream)
                
            case let .waitingForElementOrFailure(subscription, _),
                 let .subscribed(subscription, _):
                subscription.request(demand)
                
            case .finished:
                break
            }
        }
    }
    
    func cancel() {
        synchronized {
            switch state {
            case .waitingForRequest, .waitingForSubscription:
                state = .finished
                
            case let .waitingForElementOrFailure(subscription, _),
                 let .subscribed(subscription, _):
                subscription.cancel()
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
                state = .waitingForElementOrFailure(subscription, downstream)
                subscription.request(currentDemand)
                
            case .waitingForRequest, .waitingForElementOrFailure, .subscribed, .finished:
                break
            }
        }
    }
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        synchronized {
            switch state {
            case let .waitingForRequest(_, downstream),
                 let .waitingForSubscription(_, downstream),
                 let .subscribed(_, downstream):
                return downstream.receive(input)
                
            case let .waitingForElementOrFailure(subscription, downstream):
                state = .subscribed(subscription, downstream)
                return downstream.receive(input)
                
            case .finished:
                return .none
            }
        }
    }
    
    func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        synchronized {
            switch state {
            case let .waitingForRequest(_, downstream),
                 let .waitingForSubscription(_, downstream),
                 let .subscribed(_, downstream):
                state = .finished
                switch completion {
                case .finished:
                    downstream.receive(completion: .finished)
                case let .failure(error):
                    downstream.receive(completion: .failure(.upstream(error)))
                }
                
            case let .waitingForElementOrFailure(_, downstream):
                state = .finished
                switch completion {
                case .finished:
                    downstream.receive(completion: .failure(.notImmediate))
                case let .failure(error):
                    downstream.receive(completion: .failure(.upstream(error)))
                }
                
            case .finished:
                break
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
