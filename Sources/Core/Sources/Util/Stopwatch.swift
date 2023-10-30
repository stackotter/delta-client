import CoreFoundation

/// A stopwatch allows tracking the runtime of a task. Use ``Profiler`` instead if fine-grained
/// labelled measurements with support for averaging over multiple trials is required.
public struct Stopwatch {
  /// The time (from `CFAbsoluteTimeGetCurrent`) at which the stopwatch was created.
  let start: Double

  /// Creates a stopwatch starting at the current time.
  public init() {
    start = CFAbsoluteTimeGetCurrent()
  }

  /// The current duration elapsed since the creation of the stopwatch.
  public var elapsed: Duration {
    .seconds(CFAbsoluteTimeGetCurrent() - start)
  }
}
