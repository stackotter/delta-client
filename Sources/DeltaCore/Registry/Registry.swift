import Foundation

/// An error to do with the shared registry.
public enum RegistryError: LocalizedError {
  /// Failed to download data for a registry.
  case failedDownloadPixlyzerData(name: String, Error)
}

/// Holds static Minecraft data such as blocks and biomes. Delta Client populates at launch.
public enum Registry {
  public static var blockRegistry = BlockRegistry()
  public static var biomeRegistry = BiomeRegistry()
  
  /// Populates the shared registry with the pixlyzer data in a specified directory.
  ///
  /// If any pixlyzer files are missing they are automatically downloaded.
  ///
  /// - Parameter pixlyzerDirectory: A directory containing pixlyzer files.
  public static func populate(from pixlyzerDirectory: URL) throws {
    blockRegistry = try loadRegistry(from: pixlyzerDirectory)
    biomeRegistry = try loadRegistry(from: pixlyzerDirectory)
  }
  
  
  /// Load a registry from pixlyzer data in the given directory.
  ///
  /// If the required pixlyzer data is missing it is automatically downloaded.
  ///
  /// - Returns: A loaded registry.
  private static func loadRegistry<T: PixlyzerRegistry>(from pixlyzerDirectory: URL) throws -> T {
    let url = T.getDownloadURL(for: Constants.versionString)
    let file = pixlyzerDirectory.appendingPathComponent(url.lastPathComponent)
    
    if !FileManager.default.fileExists(atPath: file.path) {
      do {
        log.info("Downloading pixlyzer data: \(url.lastPathComponent)")
        try FileManager.default.createDirectory(at: pixlyzerDirectory, withIntermediateDirectories: true, attributes: nil)
        let data = try Data(contentsOf: url)
        try data.write(to: file)
      } catch {
        throw RegistryError.failedDownloadPixlyzerData(name: "\(T.self)", error)
      }
    }
    
    log.info("Loading \(url.deletingPathExtension().deletingPathExtension().lastPathComponent) registry")
    let registry = try T.load(from: file)
    return registry
  }
}
