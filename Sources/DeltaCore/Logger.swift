import Foundation
import Logging
import DeltaLogger

fileprivate func createLogger() -> Logger {
  var log = Logger(label: "DeltaCore") { label in
    DeltaLogHandler(label: label)
  }
  log.logLevel = .debug
  return log
}

var log = createLogger()
