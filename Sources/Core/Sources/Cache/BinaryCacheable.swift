import Foundation

/// Allows values of conforming types to easily be cached.
public protocol BinaryCacheable: Cacheable, RootSerializable {}

/// An error thrown by a type conforming to ``BinaryCacheable``.
public enum BinaryCacheableError: LocalizedError {
  /// Failed to load a value from a binary cache file.
  case failedToLoadFromCache(BinaryCacheable.Type, Error)
  /// Failed to cache a value to a binary cache file.
  case failedToCache(BinaryCacheable.Type, Error)

  public var errorDescription: String? {
    switch self {
      case .failedToLoadFromCache(let type, let error):
        return """
        Failed to load a value from a binary cache file.
        Type: \(String(describing: type))
        Reason: \(error.localizedDescription)
        """
      case .failedToCache(let type, let error):
        return """
        Failed to cache a value to a binary cache file.
        Type: \(String(describing: type))
        Reason: \(error.localizedDescription)
        """
    }
  }
}

public extension BinaryCacheable {
  static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      return try deserialize(fromFile: cacheDirectory.appendingPathComponent(cacheFileName))
    } catch {
      throw BinaryCacheableError.failedToLoadFromCache(Self.self, error)
    }
  }

  func cache(to directory: URL) throws {
    do {
      try serialize(toFile: directory.appendingPathComponent(Self.cacheFileName))
    } catch {
      throw BinaryCacheableError.failedToCache(Self.self, error)
    }
  }
}
