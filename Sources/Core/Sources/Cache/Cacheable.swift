import Foundation

/// Conforming types can be cached to disk with ease.
public protocol Cacheable {
  /// The default cache file name for this type.
  static var cacheFileName: String { get }
  /// Loads a cached value from a cache directory. See ``cacheFileName`` for a type's default cache
  /// file name.
  static func loadCached(from cacheDirectory: URL) throws -> Self
  /// Caches this value to a cache directory. See ``cacheFileName`` for a type's default cache file
  /// name.
  func cache(to directory: URL) throws
}

public extension Cacheable {
  static var cacheFileName: String {
    let base = String(describing: Self.self)
    let fileType: String
    if (Self.self as? JSONCacheable.Type) != nil {
      fileType = "json"
    } else {
      fileType = "bin"
    }
    return "\(base).\(fileType)"
  }
}
