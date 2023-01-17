import ArgumentParser
import Foundation
import Logging

/// An error thrown while parsing ``CommandLineArguments``.
enum CommandLineArgumentsError: LocalizedError {
  case invalidLogLevel(String)

  var errorDescription: String? {
    switch self {
      case .invalidLogLevel(let level):
        return "Invalid log level '\(level)'. Must be one of \(Logger.Level.allCases.map(\.rawValue))"
    }
  }
}

/// The command line arguments for Delta Client.
struct CommandLineArguments: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "DeltaClient")

  /// A replacement for the default plugins directory.
  @Option(
    name: .customLong("plugins-dir"),
    help: "A directory to load plugins from instead of the default plugins directory.",
    transform: URL.init(fileURLWithPath:))
  var pluginsDirectory: URL?

  /// The minimum log level to output to stdout.
  @Option(
    help: "The minimum log level to output to stdout.",
    transform: { string in
      switch string {
        case "trace":
          return .trace
        case "verbose":
          return .verbose
        case "debug":
          return .debug
        case "info":
          return .info
        case "notice":
          return .notice
        case "warning":
          return .warning
        case "error":
          return .error
        case "critical":
          return .critical
        default:
          throw CommandLineArgumentsError.invalidLogLevel(string)
      }
    })
  var logLevel = LogLevel.info

  /// Xcode passes the `-NSDocumentRevisionsDebugMode` flag when running applications (no clue why).
  /// It needs to be defined here because otherwise it throws an error due to strict parsing.
  @Option(
    name: .customLong("NSDocumentRevisionsDebugMode", withSingleDash: true),
    help: .init("Ignore this, just Xcode being weird.", visibility: .hidden))
  var nsDocumentRevisionsDebugMode: String?
}
