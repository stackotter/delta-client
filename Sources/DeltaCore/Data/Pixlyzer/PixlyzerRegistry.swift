import Foundation

/// A registry that can be loaded from the pixlyzer-data repository.
protocol PixlyzerRegistry {
  /// Create an empty registry.
  init()
  
  /// Load the registry from a pixlyzer file.
  static func load(from pixlyzerFile: URL) throws -> Self
  
  /// Get the URL to download the pixlyzer file this registry requires.
  /// - Parameter version: A Minecraft version string (e.g. "1.16.1").
  /// - Returns: The download URL for the pixlyzer file the registry loads from.
  static func getDownloadURL(for version: String) -> URL
}
