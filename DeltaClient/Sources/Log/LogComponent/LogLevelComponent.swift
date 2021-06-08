//
//  LogLevelComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy

struct LogLevelComponent: LogComponent {
  var level: LogLevel
  var shouldColor: Bool
  var extraSpace = false
  
  func toString() -> String {
    var levelString = level.shortString
      .padding(toLength: 5, withPad: " ", startingAt: 0)
    levelString = "[ \(levelString) ]" + (extraSpace ? " " : "")
    
    if shouldColor {
      levelString = levelString.colorize(level.deltaColor)
    }
    
    return levelString
  }
}
