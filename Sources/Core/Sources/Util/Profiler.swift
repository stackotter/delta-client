import Foundation
import OrderedCollections

/// A simple stack-based profiler with type safe measurement labels if required.
public final class Profiler<Label: RawRepresentable & Hashable> where Label.RawValue == String {
  public var name: String?
  public var verbose: Bool

  struct Measurement {
    var label: Label
    var seconds: Double
    var children: [Measurement]
  }

  private var children: [[Measurement]] = []
  private var measurementStarts: [(label: Label, start: Double)] = []
  private var measurements: [Measurement] = []
  private var measurementOrder: [Label] = []
  private var trials: [[Measurement]] = []

  /// Creates a new profiler.
  /// - Parameters:
  ///   - name: The profiler's display name.
  ///   - verbose: If `true`, measurements are logged as soon as they are finished.
  public init(_ name: String? = nil, verbose: Bool = false) {
    self.name = name
    self.verbose = verbose
  }

  /// Measures the execution time of a closure.
  /// - Parameters:
  ///   - label: The label for the measurement.
  ///   - task: The task to measure the execution time of.
  public func measure(_ label: Label, _ task: () throws -> Void) rethrows {
    push(label)
    try task()
    pop()
  }

  /// Gets the current time in seconds.
  public func currentSeconds() -> Double {
    return CFAbsoluteTimeGetCurrent()
  }

  public func push(_ label: Label) {
    measurementStarts.append((label: label, start: currentSeconds()))
    measurementOrder.append(label)
    children.append([])
  }

  public func pop() {
    assert(!measurementStarts.isEmpty, "pop called without matching push")
    guard
      let (label, start) = measurementStarts.popLast(),
      let measurementChildren = children.popLast()
    else {
      log.warning("Invalid use of profiler: pop called without matching push")
      return
    }

    let elapsed = currentSeconds() - start
    let measurement = Measurement(
      label: label,
      seconds: elapsed,
      children: measurementChildren
    )

    if children.isEmpty {
      // If at top level, store the measurement
      measurements.append(measurement)
    } else {
      // Otherwise, store it as a child of the parent for when the parent finishes
      children[children.count - 1].append(measurement)
    }

    if verbose {
      var message = "\(label.rawValue): \(String(format: "%.5fms", elapsed * 1000))"
      if let name = name {
        message = "\(name), \(message)"
      }
      log.debug(message)
    }
  }

  public func endTrial() {
    trials.append(measurements)
    measurements = []
  }

  public func reset() {
    measurementStarts = []
    measurements = []
    measurementOrder = []
  }

  public func printSummary(onlyLatestTrial: Bool = false) {
    let measurements: [Measurement]
    if onlyLatestTrial {
      measurements = trials.last ?? []
    } else {
      var trials = trials
      if !self.measurements.isEmpty {
        trials.append(self.measurements)
      }
      measurements = Self.average(trials)
    }

    print("=== Start profiler summary ===")
    printMeasurements(measurements)
    print("===  End profiler summary  ===")
  }

  private func printMeasurements(_ measurements: [Measurement], indent: Int = 0) {
    let longestLabel = measurements.map(\.label.rawValue.count).max() ?? 0
    let indentString = String(repeating: " ", count: indent)
    for measurement in measurements {
      let measurementString = String(
        format: "%.5fms",
        measurement.seconds * 1000
      )
      let paddingWidth = longestLabel - measurement.label.rawValue.count
      let padding = String(repeating: " ", count: paddingWidth)
      print("\(indentString)\(measurement.label.rawValue)\(padding) \(measurementString)")

      printMeasurements(measurement.children, indent: indent + 2)
    }
  }

  /// Averages a set of trials, assuming that they all contain the same structure of measurements.
  private static func average(_ trials: [[Measurement]]) -> [Measurement] {
    // Get the set of top level labels
    let labels = OrderedSet(trials.flatMap { trial in
      return trial.map(\.label)
    })

    // Average measurements with the same label
    var averagedMeasurements: [Measurement] = []
    for label in labels {
      let measurements = trials.compactMap { trial in
        return trial.first { measurement in
          return measurement.label == label
        }
      }

      guard !measurements.isEmpty else {
        continue
      }

      let durations = measurements.map(\.seconds)
      let averageSeconds = durations.reduce(0, +) / Double(durations.count)
      let children = measurements.map(\.children)
      let averagedChildren = average(children)

      averagedMeasurements.append(Measurement(
        label: label,
        seconds: averageSeconds,
        children: averagedChildren
      ))
    }

    return averagedMeasurements
  }
}
