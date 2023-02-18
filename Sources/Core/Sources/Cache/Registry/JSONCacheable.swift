import Foundation

/// Allows ``Codable`` types to easily conform to the ``Cacheable`` protocol.
public protocol JSONCacheable: Cacheable, Codable {}

public enum JSONCacheableError: LocalizedError {
  /// Failed to load a value from a JSON cache file.
  case failedToLoadFromCache(JSONCacheable.Type, Error)
  /// Failed to cache a value to a JSON cache file.
  case failedToCache(JSONCacheable.Type, Error)

  public var errorDescription: String? {
    switch self {
      case .failedToLoadFromCache(let type, let error):
        return """
        Failed to load a value from a JSON cache file.
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

public extension JSONCacheable {
  static func loadCached(from file: URL) throws -> Self {
    do {
      let data = try Data(contentsOf: file)
      return try CustomJSONDecoder().decode(Self.self, from: data)
    } catch {
      throw JSONCacheableError.failedToLoadFromCache(Self.self, error)
    }
  }

  func cache(to file: URL) throws {
    do {
      let data = try JSONEncoder().encode(self)
      try data.write(to: file)
    } catch {
      throw JSONCacheableError.failedToCache(Self.self, error)
    }
  }
}
