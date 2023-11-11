import Foundation

/// Wraps an error with an additional ``RichError/richDescription`` property for displaying
/// rich contextual errors in a UI. The `LocalizedError` implementation simply passes through
/// the implementation of the wrapped error. Can also be used to wrap a custom error message
/// instead of a localized error.
public struct RichError: LocalizedError {
  /// The base error.
  private var wrapped: Wrapped
  /// Additional key-value context.
  fileprivate var context: [(String, Any)] = []
  /// An underlying reason for the error (e.g. the file writing error which causes a resource
  /// pack caching error).
  fileprivate var reason: (any Error)?

  /// The rich error either wraps a custom error message or a localized error.
  private enum Wrapped {
    case message(String)
    case error(any LocalizedError)

    var localizedDescription: String {
      switch self {
        case .error(let error):
          return error.localizedDescription
        case .message(let message):
          return message
      }
    }
  }

  /// Wraps a localized error with a container for additional context.
  public init(_ error: any LocalizedError) {
    wrapped = .error(error)
  }

  /// Wraps a custom error message with a container for additional context.
  public init(_ message: String) {
    wrapped = .message(message)
  }

  /// Sets the underlying error which caused this error to occur. Calling it a second time
  /// overwrites the underlying error set by the previous call.
  public func becauseOf(_ error: any Error) -> RichError {
    var richError = self
    richError.reason = error
    return richError
  }

  /// Provides additional context for the error. Displayed by ``RichError/richDescription``.
  public func with(_ key: String, being value: Any) -> RichError {
    var richError = self
    richError.context.append((key, value))
    return richError
  }

  public var errorDescription: String? {
    wrapped.localizedDescription
  }

  /// A rich multi-line error message to display in UIs. Provides additional context and optionally
  /// an underlying reason.
  public var richDescription: String {
    var lines = [wrapped.localizedDescription]
    for (key, value) in context {
      lines.append("\(key): \(value)")
    }
    if let reason = reason {
      lines.append("Reason: \(reason.localizedDescription)")
    }
    return lines.joined(separator: "\n")
  }
}

extension LocalizedError {
  /// Adds an underlying reason to an error. If the error is already rich, this modifies a copy of the error
  /// instead of wrapping it in another ``RichError``. Calling this method a second time overwrites the
  /// underlying error set by the previous call.
  public func becauseOf(_ error: any Error) -> RichError {
    var richError: RichError
    if let self = self as? RichError {
      richError = self
    } else {
      richError = RichError(self)
    }

    // Don't use `RichError.becauseOf` here even though this is duplicated code (because it creates an infinite loop otherwise)
    richError.reason = error
    return richError
  }

  /// Adds key-value context to an error. If the error is already rich, this modifies a copy of the error
  /// instead of wrapping it in another ``RichError``.
  public func with(_ key: String, _ value: Any) -> RichError {
    var richError: RichError
    if let self = self as? RichError {
      richError = self
    } else {
      richError = RichError(self)
    }

    // Don't use `RichError.with` here even though this is duplicated code (because it creates an infinite loop otherwise)
    richError.context.append((key, value))
    return richError
  }
}
