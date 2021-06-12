//
//  Logger.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/12/20.
//

import Foundation
import Puppy
import Logging

/// The global DeltaClient logger
let log = Logger.makePuppyLogger(logLevel: .trace)

/// Utility for creating DeltaClient's global logger
enum Logger {
  /**
   Creates a `Puppy` logger with an `OSLogger`, `ConsoleLogger` (if in a release build)
   and a `FileRotationLogger` which logs to 'log/latest.log' in 'Application Support'.
   
   - Parameter logLevel: The initial log level for the `ConsoleLogger` to log at
   - Returns: A `Puppy` instance
   */
  static func makePuppyLogger(logLevel: LogLevel) -> Puppy {
    let log = Puppy.default
    
    // Logs to the OS' central logging system
    let oslog = OSLogger("dev.stackotter.delta-client.os-log")
    oslog.format = OSLogFormatter()
    log.add(oslog)
    
    #if !DEBUG
    // If this is a release build, log to stdout as well. We don't log to stdout in
    // debug builds because then the logs double up in XCode's console
    let console = ConsoleLogger("dev.stackotter.delta-client.console-log")
    console.format = LogFormatter(withColour: true)
    log.add(console, withLevel: .info)
    #endif
    
    // TODO: StorageManager should be a singleton if possible
    if let storageManager = try? StorageManager() {
      let logFile = storageManager.absoluteFromRelative("log/latest.log")
      do {
        let fileRotation = try FileRotationLogger("dev.stackotter.delta-client.file-rotation-log", fileURL: logFile)
        fileRotation.format = LogFormatter(withColour: false)
        fileRotation.maxFileSize = 10 * 1024 * 1024
        fileRotation.maxArchivedFilesCount = 5
        log.add(fileRotation)
      } catch {
        log.error("Failed to initialize FileRotationLogger for '\(logFile.absoluteString)'")
      }
    } else {
      log.error("Failed to initialize StorageManager to intialize FileRotationLogger")
    }
    
    LoggingSystem.bootstrap { label in
      return PuppyLogHandler(label: label, puppy: log)
    }
    
    return log
  }
}

extension Puppy {
  /** Updates the `LogLevel` of any `ConsoleLogger`s attached to this `Puppy` instance
   
   - Parameter newLogLevel: The `LogLevel` to update the `ConsoleLogger`s to
   */
  func updateConsoleLogLevel(to newLogLevel: LogLevel) {
    loggers.forEach { logger in
      if let logger = logger as? ConsoleLogger {
        logger.logLevel = newLogLevel
      }
    }
  }
}
