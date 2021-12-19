import Foundation

/// Allows `ProtobufCodable` registries to automatically be cached.
public protocol ProtobufCachableRegistry: CachableRegistry, ProtobufCachable {
  /// - Returns: File to cache the registry to. Should just be a file name ending in ".bin" (e.g. "blocks.bin"). It's a function so that `ProtobufCachableRegistry` can be implemented in extensions.
  static func getCacheFileName() -> String
}

public enum ProtobufCachableRegistryError: LocalizedError {
  /// Failed to load a registry from a Protobuf cache file.
  case failedToLoadFromCache(Error)
  /// Failed to cache a registry to a Protobuf cache file.
  case failedToCache(Error)
}

public extension ProtobufCachableRegistry {
  static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      return try self.init(fromFile: cacheDirectory.appendingPathComponent(getCacheFileName()))
    } catch {
      throw ProtobufCachableRegistryError.failedToLoadFromCache(error)
    }
  }
  
  func cache(to directory: URL) throws {
    do {
      try cache(toFile: directory.appendingPathComponent(Self.getCacheFileName()))
    } catch {
      throw ProtobufCachableRegistryError.failedToCache(error)
    }
  }
}
