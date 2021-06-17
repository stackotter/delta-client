//
//  OSLogFormatter.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy

class OSLogFormatter: LogFormatter {
  init() {
    super.init(withColour: false)
  }
  
  /**
   Formats log message for OSLogger. See `LogFormatter.formatMessage`
   
   Differs in that it leaves out the timestamp and doesn't include ANSI colours
   because XCode doesn't support them
   */
  override func formatMessage(
    _ level: LogLevel,
    message: String,
    tag: String,
    function: String,
    file: String,
    line: UInt,
    swiftLogInfo: [String: String],
    label: String,
    date: Date,
    threadID: UInt64
  ) -> String {
    
    var logLevel = LogLevelComponent(
      level: level,
      shouldColor: false)
    logLevel.extraSpace = false
    let caller = CallerComponent(
      fileName: shortFileName(file),
      line: line,
      function: function,
      color: nil)
    let message = MessageComponent(message: message)
    
    var formatted = logLevel.toString()
    if level.isError {
      formatted += " \(caller.toString())"
    }
    formatted += " \(message.toString())"
    return formatted
  }
}
