import Foundation

/// Conforming types can be cached to disk with ease.
public protocol Cacheable {
  /// The default cache file name for this type. Used for ``Cacheable/loadCached(fromDirectory:)``
  /// and ``Cacheable/cache(toDirectory:)``.
  static var defaultCacheFileName: String { get }
  /// Loads a cached value from a cache directory. See ``cacheFileName`` for a type's default cache
  /// file name.
  static func loadCached(from file: URL) throws -> Self
  /// Caches this value to a cache directory. See ``cacheFileName`` for a type's default cache file
  /// name.
  func cache(to file: URL) throws
}

public extension Cacheable {
  static var defaultCacheFileName: String {
    let base = String(describing: Self.self)
    let fileType: String
    if (Self.self as? JSONCacheable.Type) != nil {
      fileType = "json"
    } else {
      fileType = "bin"
    }
    return "\(base).\(fileType)"
  }

  static func loadCached(fromDirectory directory: URL) throws -> Self {
    return try loadCached(from: directory.appendingPathComponent(defaultCacheFileName))
  }

  func cache(toDirectory directory: URL) throws {
    try cache(to: directory.appendingPathComponent(Self.defaultCacheFileName))
  }
}
