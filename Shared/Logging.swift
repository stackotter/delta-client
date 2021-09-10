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
  var log = Logger(label: "DeltaCore") { label in
    DeltaLogHandler(label: label)
  }
  log.logLevel = .debug
  return log
}

var log = createLogger()
