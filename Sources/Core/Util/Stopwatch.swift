import Foundation

public struct Stopwatch {
  public var name: String?
  public var mode: StopwatchMode
  
  private var measurementStarts: [String: Double] = [:]
  private var measurements: [(name: String, duration: Double)] = []
  
  public enum StopwatchMode {
    case summary
    case verbose
  }
  
  public init(mode: StopwatchMode, name: String? = nil) {
    self.mode = mode
    self.name = name
  }
  
  public mutating func measure(_ name: String, _ task: () throws -> Void) rethrows {
    startMeasurement(name)
    try task()
    stopMeasurement(name)
  }
  
  public func currentMillis() -> Double {
    return CFAbsoluteTimeGetCurrent() * 1000
  }
  
  public mutating func startMeasurement(_ category: String) {
    measurementStarts[category] = currentMillis()
  }
  
  public mutating func stopMeasurement(_ category: String) {
    if let start = measurementStarts[category] {
      let measurement = currentMillis() - start
      measurements.append((name: category, duration: measurement))

      if mode == .verbose {
        var message = "\(category): \(String(format: "%.5fms", measurement))"
        if let name = name {
          message = "\(name), \(message)"
        }
        log.info(message)
      }
    }
  }
  
  public func summary(repeats: Int = 1) {
    let uniqueCategories = Set<String>(measurements.map { $0.name })
    for category in uniqueCategories {
      let categoryMeasurements = measurements.filter { $0.name == category }
      let count = categoryMeasurements.count
      let sum = categoryMeasurements.reduce(into: 0, { total, measurement in
        total += measurement.duration
      })
      let avg = sum / Double(count)
      var message = "\(category): \(String(format: "%.5fms, total: %.5fms", avg, sum / Double(repeats)))"
      if let name = name {
        message = "\(name), \(message)"
      }
      log.info(message)
    }
  }
  
  public mutating func reset() {
    measurementStarts = [:]
    measurements = []
  }
}
