import Foundation

enum Utils {
  #if os(macOS)
  /// Runs a shell command.
  static func shell(_ command: String) {
    let task = Process()
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
  }
  
  /// Relaunches the application.
  static func relaunch() {
    log.info("Relaunching Delta Client")
    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [path]
    task.launch()
    exit(0)
  }
  #endif
}
