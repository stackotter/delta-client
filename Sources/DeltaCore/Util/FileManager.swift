import Foundation

extension FileManager {
  func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let itemExists = fileExists(atPath: url.path, isDirectory: &isDirectory)
    return itemExists && isDirectory.boolValue
  }
}
