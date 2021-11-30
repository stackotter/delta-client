import Foundation
import ZippyJSON

/// Allows `Codable` registries to automatically be cached using JSON.
///
/// It's not the fastest method of caching that Delta Core uses, but it's automatic,
/// and it's acceptable for smaller registries. Try it out, and if it's not fast
/// enough, use Protobuf instead (or something better).
public protocol JSONRegistry: CachableRegistry, Codable {
  /// File to cache the registry to. Should just be a file name ending in ".json" (e.g. "blocks.json").
  static var cacheFile: String { get }
}

public enum JSONRegistryError: LocalizedError {
  case failedToLoadFromCache(JSONRegistry.Type, Error)
  case failedToCache(JSONRegistry.Type, Error)
}

extension JSONRegistry {
  public static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      let data = try Data(contentsOf: cacheDirectory.appendingPathComponent(Self.cacheFile))
      return try ZippyJSONDecoder().decode(Self.self, from: data)
    } catch {
      throw JSONRegistryError.failedToLoadFromCache(Self.self, error)
    }
  }
  
  public func cache(to directory: URL) throws {
    do {
      let data = try JSONEncoder().encode(self)
      try data.write(to: directory.appendingPathComponent(Self.cacheFile))
    } catch {
      throw JSONRegistryError.failedToCache(Self.self, error)
    }
  }
}
