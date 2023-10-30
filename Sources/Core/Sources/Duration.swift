/// A duration of time.
public struct Duration: CustomStringConvertible {
  /// The duration in seconds.
  public var seconds: Double

  /// The duration in milliseconds.
  public var milliseconds: Double {
    seconds * 1_000
  }

  /// The duration in microseconds.
  public var microseconds: Double {
    seconds * 1_000_000
  }

  /// The duration in nanoseconds.
  public var nanoseconds: Double {
    seconds * 1_000_000_000
  }

  /// A description of the duration with units appropriate for its magnitude.
  public var description: String {
    if seconds >= 1 {
      return String(format: "%.04fs", seconds)
    } else if milliseconds >= 1 {
      return String(format: "%.04fms", milliseconds)
    } else if microseconds >= 1 {
      return String(format: "%.04fμs", microseconds)
    } else {
      return String(format: "%.04fns", nanoseconds)
    }
  }

  /// Creates a duration measured in seconds.
  public static func seconds(_ seconds: Double) -> Self {
    Self(seconds: seconds)
  }

  /// Creates a duration measured in milliseconds.
  public static func milliseconds(_ milliseconds: Double) -> Self {
    Self(seconds: milliseconds / 1_000)
  }

  /// Creates a duration measured in microseconds.
  public static func microseconds(_ microseconds: Double) -> Self {
    Self(seconds: microseconds / 1_000_000)
  }

  /// Creates a duration measured in nanoseconds.
  public static func nanoseconds(_ nanoseconds: Double) -> Self {
    Self(seconds: nanoseconds / 1_000_000_000)
  }
}
