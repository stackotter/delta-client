import Foundation

/// Allows ``Codable`` types to easily conform to the ``Cachable`` protocol.
public protocol JSONCachable: Cachable, Codable {}

public enum JSONCachableError: LocalizedError {
  /// Failed to load a value from a JSON cache file.
  case failedToLoadFromCache(JSONCachable.Type, Error)
  /// Failed to cache a value to a JSON cache file.
  case failedToCache(JSONCachable.Type, Error)

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

public extension JSONCachable {
  static func loadCached(from cacheDirectory: URL) throws -> Self {
    do {
      let data = try Data(contentsOf: cacheDirectory.appendingPathComponent(cacheFileName))
      return try CustomJSONDecoder().decode(Self.self, from: data)
    } catch {
      throw JSONCachableError.failedToLoadFromCache(Self.self, error)
    }
  }

  func cache(to directory: URL) throws {
    do {
      let data = try JSONEncoder().encode(self)
      try data.write(to: directory.appendingPathComponent(Self.cacheFileName))
    } catch {
      throw JSONCachableError.failedToCache(Self.self, error)
    }
  }
}
