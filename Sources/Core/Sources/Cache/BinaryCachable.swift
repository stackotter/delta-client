import Foundation

/// Allows values of conforming types to easily be cached.
public protocol BinaryCachable: Cachable, RootSerializable {}

/// An error thrown by a type conforming to ``BinaryCachable``.
public enum BinaryCachableError: LocalizedError {
  /// Failed to load a value from a binary cache file.
  case failedToLoadFromCache(BinaryCachable.Type, Error)
  /// Failed to cache a value to a binary cache file.
  case failedToCache(BinaryCachable.Type, Error)

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

public extension BinaryCachable {
  static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      return try deserialize(fromFile: cacheDirectory.appendingPathComponent(cacheFileName))
    } catch {
      throw BinaryCachableError.failedToLoadFromCache(Self.self, error)
    }
  }

  func cache(to directory: URL) throws {
    do {
      try serialize(toFile: directory.appendingPathComponent(Self.cacheFileName))
    } catch {
      throw BinaryCachableError.failedToCache(Self.self, error)
    }
  }
}
