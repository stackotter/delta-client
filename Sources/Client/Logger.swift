import DeltaCore
import Logging

var log = createLogger("DeltaClient")

/// Sets the log level of both the Client and Core loggers.
func setLogLevel(_ level: Logger.Level) {
  log.logLevel = level
  DeltaCore.log.logLevel = level
}
