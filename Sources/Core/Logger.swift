import Foundation
import Logging
import DeltaLogger

public func createLogger(_ label: String) -> Logger {
  var log = Logger(label: label) { label in
    DeltaLogHandler(label: label)
  }
  log.logLevel = .debug
  return log
}

public var log = createLogger("DeltaCore")
