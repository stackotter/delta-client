//
//  Stopwatch.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import os

struct Stopwatch {
  var name: String?
  var mode: StopwatchMode
  
  private var measurementStarts: [String: Double] = [:]
  private var measurements: [String: [Double]] = [:]
  
  enum StopwatchMode {
    case summary
    case verbose
  }
  
  init(mode: StopwatchMode, name: String? = nil) {
    self.mode = mode
    self.name = name
  }
  
  func currentMillis() -> Double {
    return CFAbsoluteTimeGetCurrent() * 1000
  }
  
  mutating func startMeasurement(_ category: String) {
    measurementStarts[category] = currentMillis()
  }
  
  mutating func stopMeasurement(_ category: String) {
    if let start = measurementStarts[category] {
      let measurement = currentMillis() - start
      if measurements[category] == nil {
        measurements[category] = []
      }
      measurements[category]!.append(measurement)
      if mode == .verbose {
        log(category: category, message: String(format: "%.4fms", measurement))
      }
    }
  }
  
  func summary() {
    for category in measurements.keys.sorted() {
      let times = measurements[category]!
      let average = times.reduce(0.0, +) / Double(times.count)
      var message = times.count == 1 ? "" : "avg "
      message += String(format: "%.4fms", average)
      log(category: category, message: message)
    }
  }
  
  mutating func reset() {
    measurementStarts = [:]
    measurements = [:]
  }
  
  private func log(category: String, message: String) {
    Logger.log("\(name != nil ? "\(name!), " : "")\(category): \(message)")
  }
}
