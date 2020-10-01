import Combine
import Foundation

// MARK: - MaybePublisher

/// `MaybePublisher` is the protocol for publishers that publish exactly zero
/// element, or one element, or an error.
///
/// In the Combine framework, the built-in `Empty`, `Just`, `Future` and
/// `URLSession.DataTaskPublisher` are examples of publishers that conform
/// to `MaybePublisher`.
///
/// Conversely, `Publishers.Sequence` is not a maybe publisher, because not all
/// sequences contain zero or one element.
///
/// # MaybePublisher Benefits
///
/// Once you have a publisher that conforms to `MaybePublisher`, you have
/// access to two desirable tools:
///
/// - An `AnyMaybePublisher` type that hides details you don’t want to expose
///   across API boundaries. For example, the user of the publisher below knows
///   that it publishes exactly zero or one `String`, but no more:
///
///         func namePublisher() -> AnyMaybePublisher<String, Error>
///
///   You build an `AnyMaybePublisher` with the
///   `eraseToAnyMaybePublisher()` method:
///
///         myMaybePublisher.eraseToAnyMaybePublisher()
///
/// - A `sinkMaybe(receive:)` method that simplifies handling of maybe
///   publisher results:
///
///         namePublisher().sinkMaybe { result in
///             switch result {
///                 case .empty: print("no name")
///                 case let .success(name): print(name)
///                 case let .failure(error): print(error)
///             }
///         }
///
/// # Building Maybe Publishers
///
/// In order to benefit from the `MaybePublisher` protocol, you need a concrete
/// publisher that conforms to this protocol.
///
/// There are a few ways to get such a maybe publisher:
///
/// - **Compiler-checked maybe publishers** are publishers that conform to the
///   `MaybePublisher` protocol. This is the case of `Empty`, `Just` and `Fail`,
///   for example. Some publishers conditionally conform to `MaybePublisher`,
///   such as `Publishers.Map`, when the upstream publisher is a
///   maybe publisher.
///
///   When you define a publisher type that publishes exactly zero element, or
///   one element, or an error, you can turn it into a maybe publisher with
///   an extension:
///
///         struct MyMaybePublisher: Publisher { ... }
///         extension MyMaybePublisher: MaybePublisher { }
///
/// - **Runtime-checked maybe publishers** are publishers that conform to the
///   `MaybePublisher` protocol by checking, at runtime, that an upstream
///   publisher publishes exactly zero element, or one element, or an error.
///
///   You build a checked maybe publisher with one of those methods:
///
///     - `Publisher.checkMaybe()` returns a maybe publisher that fails with a
///       `MaybeError` if the upstream publisher does not publish exactly zero
///        element, or one element, or an error.
///
///     - `Publisher.assertMaybe()` returns a maybe publisher that raises a
///       fatal error if the upstream publisher does not publish exactly zero
///       element, or one element, or an error.
///
/// - **Unchecked maybe publishers**: you should only build such a maybe
///   publisher when you are sure that the `MaybePublisher` contract
///   is honored by the upstream publisher.
///
///   For example:
///
///         // CORRECT: those publish exactly zero element, or one element, or an error.
///         Array<Int>().publisher.uncheckedMaybe()
///         [1].publisher.uncheckedMaybe()
///         [1, 2].publisher.prefix(1).uncheckedMaybe()
///         someSubject.prefix(1).uncheckedMaybe()
///
///         // WRONG: publishes more than one element
///         [1, 2].publisher.uncheckedMaybe()
///
///         // WRONG: does not publish exactly zero element, or one element, or an error
///         Just(1).append(Fail(error))
///
///   The consequences of using `uncheckedMaybe()` on a publisher that does not
///   publish exactly zero element, or one element, or an error, are undefined.
///
/// # Basic Maybe Publishers
///
/// `AnyMaybePublisher` comes with factory methods that build basic
/// maybe publishers:
///
///         // Immediately completes.
///         AnyMaybePublisher.empty
///
///         // Immediately publishes one value, and then completes.
///         AnyMaybePublisher.just(value)
///
///         // Immediately fails with the given error.
///         AnyMaybePublisher.fail(error)
///
///         // Never publishes any value, never completes.
///         AnyMaybePublisher.never()
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol MaybePublisher: Publisher { }

/// The result of a maybe publisher.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum MaybeResult<Success, Failure: Error> {
    /// Completion without any element.
    case empty
    
    /// Completion with one element.
    case success(Success)
    
    /// Failure completion.
    case failure(Failure)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybeResult {
    /// Returns a new `MaybeResult`, mapping any success value using the given
    /// transformation.
    ///
    /// - Parameter transform: A closure that takes the success value of this
    ///   instance.
    /// - Returns: A `MaybeResult` instance with the result of evaluating
    ///   `transform` as the new success value if this instance represents
    ///   a success.
    @inlinable
    public func map<NewSuccess>(_ transform: (Success) -> NewSuccess)
    -> MaybeResult<NewSuccess, Failure>
    {
        switch self {
        case .empty:
            return .empty
        case let .success(success):
            return .success(transform(success))
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    /// Returns a new `MaybeResult`, mapping any failure value using the given
    /// transformation.
    ///
    /// - Parameter transform: A closure that takes the failure value of the
    ///   instance.
    /// - Returns: A `MaybeResult` instance with the result of evaluating
    ///   `transform` as the new failure value if this instance represents
    ///   a failure.
    @inlinable
    public func mapError<NewFailure>(_ transform: (Failure) -> NewFailure)
    -> MaybeResult<Success, NewFailure>
    {
        switch self {
        case .empty:
            return .empty
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return .failure(transform(failure))
        }
    }
    
    /// Returns a new `MaybeResult`, mapping any success value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// - Parameter transform: A closure that takes the success value of the
    ///   instance.
    /// - Returns: A `MaybeResult` instance with the result of evaluating
    ///   `transform` as the new failure value if this instance represents
    ///   a success.
    @inlinable
    public func flatMap<NewSuccess>(_ transform: (Success) -> MaybeResult<NewSuccess, Failure>)
    -> MaybeResult<NewSuccess, Failure>
    {
        switch self {
        case .empty:
            return .empty
        case let .success(success):
            return transform(success)
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    /// Returns a new `MaybeResult`, mapping any failure value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// - Parameter transform: A closure that takes the failure value of the
    ///   instance.
    /// - Returns: A `MaybeResult` instance, either from the closure or the
    ///   previous `.success`.
    @inlinable
    public func flatMapError<NewFailure>(
        _ transform: (Failure) -> MaybeResult<Success, NewFailure>
    ) -> MaybeResult<Success, NewFailure> {
        switch self {
        case .empty:
            return .empty
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return transform(failure)
        }
    }
    
    /// Returns the success value, if any, as a throwing expression.
    ///
    /// - Returns: The success value, if the instance represents a success, or
    ///   nil if the instance is empty.
    /// - Throws: The failure value, if the instance represents a failure.
    @inlinable
    public func get() throws -> Success? {
        switch self {
        case .empty:
            return nil
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybeResult: Equatable where Success: Equatable, Failure: Equatable { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybeResult: Hashable where Success: Hashable, Failure: Hashable { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybePublisher {
    /// Wraps this maybe publisher with a type eraser.
    ///
    /// Use `eraseToAnyMaybePublisher()` to expose an instance of
    /// AnyMaybePublisher to the downstream subscriber, rather than this
    /// publisher’s actual type.
    ///
    /// This form of type erasure preserves abstraction across API boundaries,
    /// such as different modules. When you expose your publishers as the
    /// AnyMaybePublisher type, you can change the underlying implementation
    /// over time without affecting existing clients.
    ///
    /// - returns: An `AnyMaybePublisher` wrapping this maybe publisher.
    public func eraseToAnyMaybePublisher() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(self)
    }
    
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited
    /// number of values, prior to returning the subscriber.
    ///
    /// - parameter receive: The closure to execute when the maybe publisher
    ///   completes, with zero element, or one element, or an error.
    /// - returns: A cancellable.
    public func sinkMaybe(receive: @escaping (MaybeResult<Output, Failure>) -> Void) -> AnyCancellable {
        // Assume value and completion can be received concurrently.
        let lock = NSRecursiveLock()
        var successReceived = false // protected by lock
        return sink(
            receiveCompletion: { completion in
                lock.lock()
                defer { lock.unlock() }
                switch completion {
                case let .failure(error):
                    receive(.failure(error))
                case .finished:
                    if !successReceived {
                        receive(.empty)
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

// MARK: - Checked & Unchecked Maybe Publishers

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    /// Checks that the publisher publishes exactly zero element, or one
    /// element, or an error, and turns contract violations into a `MaybeError`.
    ///
    /// See also `Publisher.assertMaybe()`.
    public func checkMaybe() -> CheckMaybePublisher<Self> {
        CheckMaybePublisher(upstream: self)
    }
    
    /// Checks that the publisher publishes exactly zero element, or one
    /// element, or an error, and raises a fatal error if the contract is
    /// not honored.
    ///
    /// See also `Publisher.checkMaybe()`.
    public func assertMaybe() -> AssertMaybePublisher<Self> {
        checkMaybe().assertNoMaybeFailure()
    }
    
    /// Turns a publisher into a maybe publisher, assuming that it publishes
    /// exactly zero element, or one element, or an error.
    ///
    /// For example:
    ///
    ///     // CORRECT: those publish exactly zero element, or one element, or an error.
    ///     Array<Int>().publisher.uncheckedMaybe()
    ///     [1].publisher.uncheckedMaybe()
    ///     [1, 2].publisher.prefix(1).uncheckedMaybe()
    ///     someSubject.prefix(1).uncheckedMaybe()
    ///
    ///     // WRONG: publishes more than one element
    ///     [1, 2].publisher.uncheckedMaybe()
    ///
    ///     // WRONG: does not publish exactly zero element, or one element, or an error
    ///     Just(1).append(Fail(error))
    ///
    /// See also `Publisher.assertMaybe()`.
    ///
    /// - warning: Violation of the maybe publisher contract are not checked.
    public func uncheckedMaybe() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(unchecked: self)
    }
}

/// The type of publishers returned by `Publisher.assertMaybe()`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias AssertMaybePublisher<Upstream: Publisher>
    = Publishers.MapError<CheckMaybePublisher<Upstream>, Upstream.Failure>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybePublisher {
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher")
    func checkMaybe() -> CheckMaybePublisher<Self> {
        CheckMaybePublisher(upstream: self)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher")
    public func assertMaybe() -> AssertMaybePublisher<Self> {
        checkMaybe().assertNoMaybeFailure()
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher: use publisher.eraseToAnyMaybePublisher() instead.")
    public func uncheckedMaybe() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(self)
    }
}

/// The error for checked maybe publishers returned
/// from `Publisher.eraseToAnyMaybePublisher()`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum MaybeError<UpstreamFailure: Error>: Error {
    /// Upstream publisher did publish more than one element
    case tooManyElements
    
    /// Upstream publisher did complete with an error after publishing one element
    case bothElementAndError
    
    /// Upstream publisher did complete with an error
    case upstream(UpstreamFailure)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybePublisher where Failure: _MaybeError {
    /// Raises a fatal error when the upstream publisher fails with a violation
    /// of the `MaybePublisher` contract, and otherwise republishes all
    /// received input.
    func assertNoMaybeFailure(file: StaticString = #file, line: UInt = #line)
    -> Publishers.MapError<Self, Failure.UpstreamFailure>
    {
        mapError { error in
            error.assertUpstreamFailure(file: file, line: line)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
protocol _MaybeError {
    associatedtype UpstreamFailure: Error
    func assertUpstreamFailure(file: StaticString, line: UInt) -> UpstreamFailure
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MaybeError: _MaybeError {
    func assertUpstreamFailure(file: StaticString, line: UInt) -> UpstreamFailure {
        switch self {
        case .tooManyElements:
            fatalError("Maybe violation: too many elements at \(file):\(line)")
        case .bothElementAndError:
            fatalError("Maybe violation: error completion after one element was published \(file):\(line)")
        case let .upstream(error):
            return error
        }
    }
}

// MARK: - AnyMaybePublisher

/// A publisher that performs type erasure by wrapping another maybe publisher.
///
/// `AnyMaybePublisher` is a concrete implementation of `MaybePublisher` that
/// has no significant properties of its own, and passes through elements and
/// completion values from its upstream publisher.
///
/// Use `AnyMaybePublisher` to wrap a publisher whose type has details you
/// don’t want to expose across API boundaries, such as different modules.
///
/// You can use `eraseToAnyMaybePublisher()` operator to wrap a publisher
/// with `AnyMaybePublisher`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AnyMaybePublisher<Output, Failure: Error>: MaybePublisher {
    public typealias Failure = Failure
    fileprivate let upstream: AnyPublisher<Output, Failure>
    
    /// Creates a type-erasing publisher to wrap the unchecked maybe publisher.
    ///
    /// See `Publisher.uncheckedMaybe()`.
    fileprivate init<P>(unchecked publisher: P)
    where P: Publisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the unchecked maybe publisher.
    ///
    /// See `Publisher.uncheckedMaybe()`.
    @available(*, deprecated, message: "Publisher is already a maybe publisher: use AnyMaybePublisher.init(_:) instead.")
    fileprivate init<P>(unchecked publisher: P)
    where P: MaybePublisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = publisher.eraseToAnyPublisher()
    }
    
    /// Creates a type-erasing publisher to wrap the provided maybe publisher.
    ///
    /// See `MaybePublisher.eraseToAnyPublisher()`.
    public init<P>(_ maybePublisher: P)
    where P: MaybePublisher, P.Failure == Self.Failure, P.Output == Output
    {
        self.upstream = maybePublisher.eraseToAnyPublisher()
    }
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Self.Failure, S.Input == Output
    {
        upstream.receive(subscriber: subscriber)
    }
}

// MARK: - Canonical Maybe Publishers

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AnyMaybePublisher where Failure == Never {
    /// Creates an `AnyMaybePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output) -> Self {
        Just(value).eraseToAnyMaybePublisher()
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AnyMaybePublisher {
    /// Creates an `AnyMaybePublisher` which immediately completes.
    ///
    /// There is no `empty(completeImmediately:)`: see `never()`.
    public static func empty() -> Self {
        Empty().eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` which immediately completes.
    ///
    /// There is no `empty(completeImmediately:outputType:failureType:)`:
    /// see `never(outputType:failureType:)`.
    public static func empty(outputType: Output.Type, failureType: Failure.Type) -> Self {
        Empty(outputType: outputType, failureType: failureType).eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output, failureType: Failure.Type = Self.Failure) -> Self {
        Just(value)
            .setFailureType(to: failureType)
            .eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure) -> Self {
        Fail(error: error).eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` that immediately terminates with the
    /// specified error.
    public static func fail(_ error: Failure, outputType: Output.Type) -> Self {
        Fail(outputType: outputType, failure: error).eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` which never completes.
    public static func never() -> Self {
        Empty(completeImmediately: false).eraseToAnyMaybePublisher()
    }
    
    /// Creates an `AnyMaybePublisher` which never completes.
    public static func never(outputType: Output.Type, failureType: Failure.Type) -> Self {
        Empty(completeImmediately: false, outputType: outputType, failureType: failureType).eraseToAnyMaybePublisher()
    }
}

// MARK: - CheckMaybePublisher

/// A maybe publisher that checks that another publisher publishes exactly zero
/// element, or one element, or an error.
///
/// `CheckMaybePublisher` can fail with a `MaybeError`:
///
/// - `.tooManyElements`: Upstream publisher did publish more than one element.
///
/// - `.bothElementAndError`: Upstream publisher did publish one element and
///   then an error.
///
/// - `.upstream(error)`: Upstream publisher did complete with an error.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct CheckMaybePublisher<Upstream: Publisher>: MaybePublisher {
    public typealias Output = Upstream.Output
    public typealias Failure = MaybeError<Upstream.Failure>
    
    let upstream: Upstream
    
    public func receive<S>(subscriber: S)
    where S: Combine.Subscriber, S.Failure == Self.Failure, S.Input == Output
    {
        let subscription = CheckMaybeSubscription(
            upstream: upstream,
            downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private class CheckMaybeSubscription<Upstream: Publisher, Downstream: Subscriber>: Subscription, Subscriber
where
    Downstream.Input == Upstream.Output,
    Downstream.Failure == MaybeError<Upstream.Failure>
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
                case let .waitingForElement(_, downstream):
                    downstream.receive(completion: .finished)
                    state = .finished
                    
                case let .waitingForCompletion(element, _, downstream):
                    _ = downstream.receive(element)
                    downstream.receive(completion: .finished)
                    state = .finished
                    
                case .waitingForRequest, .waitingForSubscription, .finished:
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
extension Publishers.AllSatisfy: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.AssertNoFailure: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Autoconnect: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Breakpoint: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Catch: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest: MaybePublisher
where A: MaybePublisher, B: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest3: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.CombineLatest4: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher, D: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Contains: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.ContainsWhere: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Count: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Delay: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.FlatMap: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.HandleEvents: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MakeConnectable: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Map: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapError: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath2: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.MapKeyPath3: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Print: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.ReceiveOn: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Retry: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SetFailureType: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SubscribeOn: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.SwitchToLatest: MaybePublisher
where Upstream: MaybePublisher, P: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryAllSatisfy: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryCatch: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryContainsWhere: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.TryMap: MaybePublisher
where Upstream: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Deferred: MaybePublisher
where DeferredPublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip: MaybePublisher
where A: MaybePublisher, B: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip3: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Zip4: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher, D: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Result.Publisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLSession.DataTaskPublisher: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Empty: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Fail: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Future: MaybePublisher { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Just: MaybePublisher { }
