import Foundation
import ZippyJSON

/// Allows `Codable` registries to automatically be cached using JSON.
///
/// It's not the fastest method of caching that Delta Core uses, but it's automatic,
/// and it's acceptable for smaller registries. Try it out, and if it's not fast
/// enough, use Protobuf instead (or something better).
public protocol JSONCachableRegistry: CachableRegistry, Codable {
  /// File to cache the registry to. Should just be a file name ending in ".json" (e.g. "blocks.json").
  ///
  /// It's a function so that `JSONCachableRegistry` can be implemented in extensions.
  static func getCacheFileName() -> String
}

public enum JSONCachableRegistryError: LocalizedError {
  /// Failed to load a registry from a JSON cache file.
  case failedToLoadFromCache(JSONCachableRegistry.Type, Error)
  /// Failed to cache a registry to a JSON cache file.
  case failedToCache(JSONCachableRegistry.Type, Error)
}

public extension JSONCachableRegistry {
  static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      let data = try Data(contentsOf: cacheDirectory.appendingPathComponent(getCacheFileName()))
      return try CustomJSONDecoder().decode(Self.self, from: data)
    } catch {
      throw JSONCachableRegistryError.failedToLoadFromCache(Self.self, error)
    }
  }
  
  func cache(to directory: URL) throws {
    do {
      let data = try JSONEncoder().encode(self)
      try data.write(to: directory.appendingPathComponent(Self.getCacheFileName()))
    } catch {
      throw JSONCachableRegistryError.failedToCache(Self.self, error)
    }
  }
}
