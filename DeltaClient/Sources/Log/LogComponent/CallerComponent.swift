//
//  CallerComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy

struct CallerComponent: LogComponent {
  var fileName: String
  var line: UInt
  var function: String
  var color: LogColor?
  
  func toString() -> String {
    var callerInfo: String
    if let color = color {
      callerInfo = "At \(fileName):\(line) \(function)"
      callerInfo = callerInfo.colorize(color)
    } else {
      // when there is no color we use angle bracket to separate
      callerInfo = "At \(fileName):\(line) \(function) >"
    }
    return callerInfo
  }
}
