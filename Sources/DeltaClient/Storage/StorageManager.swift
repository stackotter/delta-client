import Foundation
import ZIPFoundation

/// A manager that provides all of the functionality DeltaClient needs to interact with the file system.
class StorageManager {
  /// Delta client's default storage manager.
  static var `default` = StorageManager()
  
  /// Whether this is the first time the app has been launched or not.
  public let isFirstLaunch: Bool
  /// The directory to store all of the client's persistent data.
  public var storageDirectory: URL
  /// The directory within the storage directory to store the vanilla assets.
  public var vanillaAssetsDirectory: URL { storageDirectory.appendingPathComponent("assets") }
  /// The directory within the storage directory to store registry data.
  public var registryDirectory: URL { storageDirectory.appendingPathComponent("registries") }
  
  /// Directory that should be used for caching.
  public var cacheDirectory: URL {
    return storageDirectory.appendingPathComponent("cache")
  }
  
  private init() {
    // Get the url of the storage directory
    if let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      storageDirectory = applicationSupport.appendingPathComponent("dev.stackotter.delta-client")
    } else {
      log.warning("Failed to get application support directory, using temporary directory instead")
      DeltaClientApp.modalWarning("Failed to get application support directory, using temporary directory instead")
      let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("dev.stackotter.delta-client.fallback")
      storageDirectory = fallback
    }
    
    let storagePath = storageDirectory.path
    log.trace("Using \(storagePath) as storage directory")
    
    // Create the storage directory if required
    if !Self.directoryExists(at: storageDirectory) {
      do {
        log.info("Creating application support directory")
        try? FileManager.default.removeItem(at: storageDirectory)
        try Self.createDirectory(at: storageDirectory)
      } catch {
        DeltaClientApp.fatal("Failed to create storage directory: \(error)")
      }
    }
    
    // Check if this is a fresh launch of the app
    let launchMarker = storageDirectory.appendingPathComponent(".haslaunched")
    isFirstLaunch = !Self.fileExists(at: launchMarker)
    if isFirstLaunch {
      // Backup the current contents of the directory in case this a forced fresh install
      do {
        try createBackup()
        try resetStorage()
      } catch {
        DeltaClientApp.fatal("Failed to reset storage for fresh install: \(error)")
      }
      
      // Create the launch marker
      FileManager.default.createFile(
        atPath: launchMarker.path,
        contents: nil,
        attributes: nil)
    }
  }
  
  // MARK: Static shortenings of FileManager methods
  
  /// Checks if a file or directory exists at the given url.
  private static func itemExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
  }
  
  /// Checks if a file or directory exists at the given url updating isDirectory.
  private static func itemExists(at url: URL, isDirectory: inout ObjCBool) -> Bool {
    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
  }
  
  /// Checks if a file exists at the given url.
  private static func fileExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return itemExists(at: url, isDirectory: &isDirectory) && !isDirectory.boolValue
  }
  
  /// Checks if a directory exists at the given url.
  private static func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return itemExists(at: url, isDirectory: &isDirectory) && isDirectory.boolValue
  }
  
  /// Creates a directory at the given url with intermediate directories.
  /// Replaces any existing item at the url with an empty directory.
  private static func createDirectory(at url: URL) throws {
    try? FileManager.default.removeItem(at: url)
    try FileManager.default.createDirectory(
      at: url, withIntermediateDirectories: true, attributes: nil)
  }
  
  private static func contentsOfDirectory(at url: URL) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(
      at: url, includingPropertiesForKeys: nil, options: [])
  }
  
  // MARK: Instance method aliases of the static methods to clean up api
  
  /// Checks if a file or directory exists at the given url.
  public func itemExists(at url: URL) -> Bool {
    return Self.itemExists(at: url)
  }
  
  /// Checks if a file or directory exists at the given url updating isDirectory.
  public func itemExists(at url: URL, isDirectory: inout ObjCBool) -> Bool {
    return Self.itemExists(at: url, isDirectory: &isDirectory)
  }
  
  /// Checks if a file exists at the given url.
  public func fileExists(at url: URL) -> Bool {
    return Self.fileExists(at: url)
  }
  
  /// Checks if a directory exists at the given url.
  public func directoryExists(at url: URL) -> Bool {
    return Self.directoryExists(at: url)
  }
  
  /// Creates a directory at the given url with intermediate directories.
  /// Replaces any existing item at the url with an empty directory.
  public func createDirectory(at url: URL) throws {
    // Remove the current item if it exists
    try Self.createDirectory(at: url)
  }
  
  public func contentsOfDirectory(at url: URL) throws -> [URL] {
    return try Self.contentsOfDirectory(at: url)
  }
  
  // MARK: Delta client specific methods
  
  /// Returns the absolute URL of a path relative to the storage directory.
  public func absoluteFromRelative(_ relativePath: String) -> URL {
    return storageDirectory.appendingPathComponent(relativePath)
  }
  
  /// Create a zip backup of the storage directory.
  public func createBackup() throws {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH-mm-ss"
    
    let backupName = "backup \(formatter.string(from: date))"
    let backupFile = absoluteFromRelative("\(backupName).zip")
    
    do {
      try FileManager.default.zipItem(at: storageDirectory, to: backupFile)
    } catch {
      throw StorageError.failedToCreateBackup(error)
    }
  }
  
  /// Unzips the specified item to the specified directory creating the directory if required.
  public func unzipItem(at item: URL, to destination: URL) throws {
    try createDirectory(at: destination)
    try FileManager.default.unzipItem(at: item, to: destination)
  }
  
  /// Copies the specified item to the destination directory.
  public func copyItem(at item: URL, to destination: URL) throws {
    try FileManager.default.copyItem(at: item, to: destination)
  }
  
  /// Delete the application support directory's contents excluding backups.
  private func resetStorage() throws {
    let contents = try FileManager.default.contentsOfDirectory(
      at: storageDirectory,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles)
    
    for item in contents {
      // Remove item if it is not a backup
      if !item.lastPathComponent.hasPrefix("backup") {
        try FileManager.default.removeItem(at: item)
      }
    }
  }
}
