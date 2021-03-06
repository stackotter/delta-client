//
//  Stopwatch.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import os

struct Stopwatch {
  var start: CFAbsoluteTime = 0
  var label: String
  var lastLap: CFAbsoluteTime = 0
  
  private init(start: CFAbsoluteTime, label: String) {
    self.start = start
    self.label = label
    self.lastLap = start
  }
  
  static func now(label: String) -> Stopwatch {
    return Stopwatch(start: CFAbsoluteTimeGetCurrent(), label: label)
  }
  
  func timeSinceLap() -> Double {
    let secs = CFAbsoluteTimeGetCurrent() - lastLap
    return secs * 1000
  }
  
  func getElapsedMs() -> Double {
    let elapsedSecs = CFAbsoluteTimeGetCurrent() - start
    return elapsedSecs * 1000
  }
  
  mutating func lap(detail: String? = nil) {
    var message: String = "\(label)"
    
    if detail != nil {
      message += ", \(detail!)"
    }
    
    let sinceLap = timeSinceLap()
    let elapsed = getElapsedMs()
    message += String(format: ": %.4fms elapsed, %.4fms since last lap", elapsed, sinceLap)
    Logger.debug(message)
    
    lastLap = CFAbsoluteTimeGetCurrent()
  }
}
