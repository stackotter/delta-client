//
//  LogFormatter.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy
import Logging

/// Defines the format for log messages in DeltaClient
class LogFormatter: LogFormattable {
  var colorMessages: Bool
  
  init(withColour colorMessages: Bool) {
    self.colorMessages = colorMessages
  }
  
  // swiftlint:disable function_parameter_count
  /**
   Formats log messages using information about the origin of the log.
   
   - Parameters:
   - level: The message's `LogLevel`
   - message: The message
   - function: The selector of the originating function
   - file: The full file path of the originating file
   - line: The originating line in `file` of the log
   - swiftLogInfo: Extra information given by swift log
   - label: The label of the logger used
   - date: The timestamp of the log as a `Date`
   - threadID: The id of the originating thread
   
   - Returns: The formatted log message.
   */
  func formatMessage(
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
    var components: [LogComponent] = [
      TimeStampComponent(date: date),
      LogLevelComponent(level: level, shouldColor: colorMessages)
    ]
    
    if level.isError {
      let callerComponent = CallerComponent(
        fileName: shortFileName(file),
        line: line,
        function: function,
        color: .red)
      components.append(callerComponent)
    }
    
    let messageComponent = MessageComponent(message: message)
    components.append(messageComponent)
    
    return components.map { component in
      return component.toString()
    }.joined(separator: " ")
  }
  // swiftlint:enable function_parameter_count
}
