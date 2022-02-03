import Foundation

enum Utils {
  static func shell(_ command: String) {
    let task = Process()
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
  }
}
