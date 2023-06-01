import Puppy
import Foundation
import Rainbow

@_exported import enum Puppy.LogLevel

struct ConsoleLogFormatter: LogFormattable {
  func formatMessage(
    _ level: LogLevel,
    message: String,
    tag: String,
    function: String,
    file: String,
    line: UInt,
    swiftLogInfo: [String : String],
    label: String,
    date: Date,
    threadID: UInt64
  ) -> String {
    let levelString: String
    switch level {
      case .trace:
        levelString = "TRACE".lightWhite
      case .verbose:
        levelString = "VERBO".magenta
      case.debug:
        levelString = "DEBUG".green
      case .info:
        levelString = "INFO ".lightBlue
      case .notice:
        levelString = "NOTE ".lightYellow
      case .warning:
        levelString = "WARN ".yellow.bold
      case .error:
        levelString = "ERROR".red.bold
      case .critical:
        levelString = "CRIT ".red.bold
    }
    return "[\(levelString)] \(message)"
  }
}

struct FileLogFormatter: LogFormattable {
  func formatMessage(
    _ level: LogLevel,
    message: String,
    tag: String,
    function: String,
    file: String,
    line: UInt,
    swiftLogInfo: [String : String],
    label: String,
    date: Date,
    threadID: UInt64
  ) -> String {
    let date = dateFormatter(date, withFormatter: DateFormatter())
    let moduleName = moduleName(file)
    return "[\(date)] [\(moduleName)] [\(level)] \(message)"
  }
}

var consoleLogger = ConsoleLogger(
  "dev.stackotter.delta-client.ConsoleLogger",
  logLevel: .debug,
  logFormat: ConsoleLogFormatter()
)

func createLogger() -> Puppy {
  Rainbow.enabled = ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") ? false : Rainbow.enabled
  var log = Puppy()
  log.add(consoleLogger)
  return log
}

public var log = createLogger()

public func setConsoleLogLevel(_ logLevel: LogLevel) {
  log.remove(consoleLogger)
  consoleLogger = ConsoleLogger(
    "dev.stackotter.delta-client.ConsoleLogger",
    logLevel: logLevel,
    logFormat: ConsoleLogFormatter()
  )
  log.add(consoleLogger)
}

public func enableFileLogger(loggingTo file: URL) throws {
  let rotationConfig = RotationConfig(
    suffixExtension: .date_uuid,
    maxFileSize: 5 * 1024 * 1024,
    maxArchivedFilesCount: 3
  )
  let fileLogger = try FileRotationLogger(
    "dev.stackotter.delta-client.FileRotationLogger",
    logLevel: .debug,
    logFormat: FileLogFormatter(),
    fileURL: file.absoluteURL,
    rotationConfig: rotationConfig
  )
  log.add(fileLogger)
}
