import ArgumentParser
import Foundation

/// The command line arguments for Delta Client.
struct CommandLineArguments: ParsableArguments {
  @Flag(help: "Show help")
  var help = false
  
  @Option(name: .customLong("plugins-dir"), help: "A directory to load plugins from instead of the default plugins directory.", transform: URL.init(fileURLWithPath:))
  var pluginsDirectory: URL?
  
  @Option(name: .customLong("NSDocumentRevisionsDebugMode", withSingleDash: true), help: "Ignore this, just Xcode being weird.")
  var nsDocumentRevisionsDebugMode: String?
}
