import Foundation

enum Utils {
  static func shell(_ command: String) {
    let task = Process()
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
  }
  
  /// Relaunches the application
  static func relaunch() {
    log.info("Relaunching delta-client")
    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [path]
    task.launch()
    exit(0)
  }
}
