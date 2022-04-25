import Foundation
import Logging
import DeltaLogger

private func createLogger() -> Logger {
  var log = Logger(label: "DeltaCore") { label in
    DeltaLogHandler(label: label)
  }
  log.logLevel = .debug
  return log
}

public var log = createLogger()
