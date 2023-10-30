import Foundation

/// An interface to the file system (a better version of `FileManager.default` from `Foundation`).
public enum FileSystem {
  /// Gets whether a file or directory exists at the specified URL.
  public static func itemExists(_ item: URL) -> Bool {
    return FileManager.default.fileExists(atPath: item.path)
  }

  /// Gets whether a given directory exists.
  public static func directoryExists(_ directory: URL) -> Bool {
    var isDirectory = ObjCBool(false)
    let itemExists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)
    return itemExists && isDirectory.boolValue
  }

  /// Gets whether a given file exists (`false` if the URL points to a directory).
  public static func fileExists(_ file: URL) -> Bool {
    var isDirectory = ObjCBool(false)
    let itemExists = FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory)
    return itemExists && !isDirectory.boolValue
  }

  /// Gets the direct descendants of a directory.
  public static func children(of directory: URL) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
  }

  /// Deletes the given file or directory.
  public static func remove(_ item: URL) throws {
    try FileManager.default.removeItem(at: item)
  }

  /// Creates a directory (including any required intermediate directories).
  public static func createDirectory(_ directory: URL) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }
}
