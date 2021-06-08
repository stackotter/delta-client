//
//  LogLevel.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy

extension LogLevel {
  private static var errorLevels: [LogLevel] = [
    LogLevel.error,
    LogLevel.critical]
  
  var isError: Bool {
    return LogLevel.errorLevels.contains(self)
  }
  
  var shortString: String {
    switch self {
      case .trace: return "trace"
      case .debug: return "debug"
      case .info: return "info"
      case .notice: return "note"
      case .verbose: return "trace"
      case .warning: return "warn"
      case .error: return "error"
      case .critical: return "crit"
    }
  }
  
  var deltaColor: LogColor {
    switch self {
      case .trace: return .lightGray
      case .debug: return .lightGray
      case .info: return .blue
      case .notice: return .green
      case .verbose: return .lightGray
      case .warning: return .yellow
      case .error: return .lightRed
      case .critical: return .red
    }
  }
}
