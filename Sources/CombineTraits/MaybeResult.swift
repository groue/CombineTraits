/// The result of a maybe publisher.
public enum MaybeResult<Success, Failure: Error> {
    /// The publisher finished normally without publishing any element.
    case finished
    
    /// The publisher published an element and finished normally.
    case success(Success)
    
    /// The publisher stopped publishing due to the indicated error.
    case failure(Failure)
}

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
        case .finished:
            return .finished
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
        case .finished:
            return .finished
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
        case .finished:
            return .finished
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
        case .finished:
            return .finished
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return transform(failure)
        }
    }
    
    /// Returns the success value, if any, as a throwing expression.
    ///
    /// - Returns: The success value, if the instance represents a success, or
    ///   nil if the instance is finished.
    /// - Throws: The failure value, if the instance represents a failure.
    @inlinable
    public func get() throws -> Success? {
        switch self {
        case .finished:
            return nil
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }
}

extension MaybeResult: Equatable where Success: Equatable, Failure: Equatable { }
extension MaybeResult: Hashable where Success: Hashable, Failure: Hashable { }
