//
//  Logging.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/6/21.
//

import Foundation
import DeltaLogger
import Logging

fileprivate func createLogger() -> Logger {
  LoggingSystem.bootstrap(DeltaLogHandler.init)
  var logger = Logger(label: "DeltaClient")
  logger.logLevel = Logger.Level.debug
  return logger
}

let log = createLogger()
