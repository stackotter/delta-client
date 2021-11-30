import Foundation

/// A cachable registry for holding static Minecraft data (e.g. block data or entity data).
///
/// Cachable means the registry can be cached to, and loaded from, disk.
public protocol CachableRegistry {
  /// Loads the registry from a cache directory.
  ///
  /// Should assume that ``cache(to:)`` has been run in the same directory already.
  static func loadCached(from cacheDirectory: URL) throws -> Self
  
  /// Caches the registry to a cache directory.
  func cache(to directory: URL) throws
}
