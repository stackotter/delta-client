import DeltaCore
import Foundation

final class StorageManager {
	static var `default` = StorageManager()

	public var storageDirectory: URL

	public var assetsDirectory: URL
	public var registryDirectory: URL
	public var cacheDirectory: URL

	private init() {
		if let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			storageDirectory = applicationSupport.appendingPathComponent("delta-client")
		} else {
			log.warning("Failed to get application support directory, using temporary directory instead")
			let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("delta-client.fallback")
			storageDirectory = fallback
		}

		assetsDirectory = storageDirectory.appendingPathComponent("assets")
		registryDirectory = storageDirectory.appendingPathComponent("registries")
		cacheDirectory = storageDirectory.appendingPathComponent("cache")

		log.trace("Using \(storageDirectory.path) as storage directory")

		if (!Self.directoryExists(at: storageDirectory)) {
			do {
				log.info("Creating storage directory")
				try? FileManager.default.removeItem(at: storageDirectory)
				try Self.createDirectory(at: storageDirectory)
			} catch {
				DeltaClientApp.fatal("Failed to create storage directory")
			}
		}
	}

	// MARK: Static shortenings of FileManager methods

  /// Checks if a file or directory exists at the given url.
  static func itemExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
  }

  /// Checks if a file or directory exists at the given url updating isDirectory.
  static func itemExists(at url: URL, isDirectory: inout ObjCBool) -> Bool {
    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
  }

  /// Checks if a file exists at the given url.
  static func fileExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return itemExists(at: url, isDirectory: &isDirectory) && !isDirectory.boolValue
  }

  /// Checks if a directory exists at the given url.
  static func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return itemExists(at: url, isDirectory: &isDirectory) && isDirectory.boolValue
  }

  /// Creates a directory at the given url with intermediate directories.
  /// Replaces any existing item at the url with an empty directory.
  static func createDirectory(at url: URL) throws {
    try? FileManager.default.removeItem(at: url)
    try FileManager.default.createDirectory(
      at: url, withIntermediateDirectories: true, attributes: nil)
  }

	/// Returns the contents of a directory at the given URL.
  static func contentsOfDirectory(at url: URL) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(
      at: url, includingPropertiesForKeys: nil, options: []
    )
  }

	/// Copies the specified item to the destination directory.
  static func copyItem(at item: URL, to destination: URL) throws {
    try FileManager.default.copyItem(at: item, to: destination)
  }

  // MARK: Delta Client specific methods

  /// Returns the absolute URL of a path relative to the storage directory.
  public func absoluteFromRelative(_ relativePath: String) -> URL {
    return storageDirectory.appendingPathComponent(relativePath)
  }
}