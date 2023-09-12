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
///                 case .finished: print("no name")
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
///     Publisher.assertMaybe()` returns a maybe publisher that raises a
///     fatal error if the upstream publisher does not publish exactly zero
///     element, or one element, or an error.
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
///         Just(1).append(Fail(error)).uncheckedMaybe()
///
///   The consequences of using `uncheckedMaybe()` on a publisher that does not
///   publish exactly zero element, or one element, or an error, are undefined.
///
/// # Basic Maybe Publishers
///
/// `AnyMaybePublisher` comes with factory methods that build basic
/// maybe publishers:
///
///         // Completes without publishing any value.
///         AnyMaybePublisher.empty()
///
///         // Publishes one value, and then completes.
///         AnyMaybePublisher.just(value)
///
///         // Fails with the given error.
///         AnyMaybePublisher.fail(error)
///
///         // Never publishes any value, never completes.
///         AnyMaybePublisher.never()
public protocol MaybePublisher<Output, Failure>: Publisher { }

extension MaybePublisher {
    /// Wraps this maybe publisher with a type eraser.
    ///
    /// Use `eraseToAnyMaybePublisher()` to expose an instance of
    /// `AnyMaybePublisher` to the downstream subscriber, rather than this
    /// publisher’s actual type.
    ///
    /// This form of type erasure preserves abstraction across API boundaries,
    /// such as different modules. When you expose your publishers as the
    /// `AnyMaybePublisher` type, you can change the underlying implementation
    /// over time without affecting existing clients.
    ///
    /// - returns: An `AnyMaybePublisher` wrapping this maybe publisher.
    public func eraseToAnyMaybePublisher() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(self)
    }
    
    /// Replaces an empty stream with the provided error.
    ///
    /// Use `replaceEmpty(withError:)` to provide a replacement failure if the
    /// upstream publisher finishes without producing any elements.
    ///
    /// - parameter error: An error to emit when the upstream publisher finishes
    ///   without emitting any elements.
    /// - returns: A single publisher that replaces an empty stream with the
    ///   provided error.
    public func replaceEmpty(withError error: Failure) -> AnySinglePublisher<Output, Failure> {
        map { Optional.some($0) }
            .replaceEmpty(with: nil)
            .flatMap { output -> AnySinglePublisher<Output, Failure> in
                if let output {
                    return .just(output)
                } else {
                    return .fail(error)
                }
            }
            .eraseToAnySinglePublisher()
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

// MARK: - Checked & Unchecked Maybe Publishers

extension Publisher {
    /// Checks that the publisher publishes exactly zero element, or one
    /// element, or an error, and turns contract violations into a `MaybeError`.
    ///
    /// See also `Publisher.assertMaybe()`.
    func checkMaybe() -> CheckMaybePublisher<Self> {
        CheckMaybePublisher(upstream: self)
    }
    
    /// Checks that the publisher publishes exactly zero element, or one
    /// element, or an error, and raises a fatal error if the contract is
    /// not honored.
    ///
    /// - Parameters:
    ///   - prefix: A string used at the beginning of the fatal error message.
    ///   - file: A filename used in the error message. This defaults to `#file`.
    ///   - line: A line number used in the error message. This defaults to `#line`.
    /// - Returns: A publisher that raises a fatal error when its upstream publisher fails.
    public func assertMaybe(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertMaybePublisher<Self> {
        checkMaybe().assertNoMaybeFailure(prefix, file: file, line: line)
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
    ///     Just(1).append(Fail(error)).uncheckedMaybe()
    ///
    /// See also `Publisher.assertMaybe()`.
    ///
    /// - warning: Violation of the maybe publisher contract are not checked.
    public func uncheckedMaybe() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(unchecked: self)
    }
}

/// The type of publishers returned by `Publisher.assertMaybe()`.
public typealias AssertMaybePublisher<Upstream: Publisher>
    = Publishers.MapError<CheckMaybePublisher<Upstream>, Upstream.Failure>

extension MaybePublisher {
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher")
    func checkMaybe() -> CheckMaybePublisher<Self> {
        CheckMaybePublisher(upstream: self)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher")
    public func assertMaybe(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> AssertMaybePublisher<Self> {
        checkMaybe().assertNoMaybeFailure(prefix, file: file, line: line)
    }
    
    /// :nodoc:
    @available(*, deprecated, message: "Publisher is already a maybe publisher: use publisher.eraseToAnyMaybePublisher() instead.")
    public func uncheckedMaybe() -> AnyMaybePublisher<Output, Failure> {
        AnyMaybePublisher(self)
    }
}

protocol _MaybeError {
    associatedtype UpstreamFailure: Error
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure
}

/// The error for checked maybe publishers.
public enum MaybeError<UpstreamFailure: Error>: Error, _MaybeError {
    /// Upstream publisher did publish more than one element
    case tooManyElements
    
    /// Upstream publisher did complete with an error after publishing one element
    case bothElementAndError
    
    /// Upstream publisher did complete with an error
    case upstream(UpstreamFailure)
    
    func assertUpstreamFailure(_ prefix: String, file: StaticString, line: UInt) -> UpstreamFailure {
        switch self {
        case .tooManyElements:
            fatalError([prefix, "Maybe violation: too many elements at \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
        case .bothElementAndError:
            fatalError([prefix, "Maybe violation: error completion after one element was published \(file):\(line)"].filter { !$0.isEmpty }.joined(separator: " "))
        case let .upstream(error):
            return error
        }
    }
}

extension MaybePublisher where Failure: _MaybeError {
    /// Raises a fatal error when the upstream publisher fails with a violation
    /// of the `MaybePublisher` contract, and otherwise republishes all
    /// received input.
    fileprivate func assertNoMaybeFailure(_ prefix: String, file: StaticString, line: UInt)
    -> Publishers.MapError<Self, Failure.UpstreamFailure>
    {
        mapError { error in
            error.assertUpstreamFailure(prefix, file: file, line: line)
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

extension AnyMaybePublisher where Failure == Never {
    /// Creates an `AnyMaybePublisher` which emits one value, and
    /// then finishes.
    public static func just(_ value: Output) -> Self {
        Just(value).eraseToAnyMaybePublisher()
    }
}

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
    public static func just(_ value: Output, failureType: Failure.Type = Self.Failure.self) -> Self {
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
