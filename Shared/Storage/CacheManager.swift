//
//  CacheManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 2/7/21.
//

import Foundation
import SwiftProtobuf

/// CacheManager provides all of the functionality DeltaClient requires for its caching needs.
///
/// It uses protobuf to serialize and deserialize.
class CacheManager {
  public static var `default` = CacheManager()
  
  /// The directory to cache to.
  private var cacheDirectory: URL
  
  /// Creates a new cache manager.
  private init() {
    cacheDirectory = StorageManager.default.absoluteFromRelative("cache")
    
    if !StorageManager.default.directoryExists(at: cacheDirectory) {
      do {
        try StorageManager.default.createDirectory(at: cacheDirectory)
      } catch {
        DeltaClientApp.fatal("Failed to create cache directory: \(error)")
      }
    }
  }
  
  /// Returns the absolute url for the cache with the given name.
  public func urlForCache(named name: String) -> URL {
    return cacheDirectory.appendingPathComponent(name)
  }
  
  /// Returns whether a cache exists with the given name or not.
  public func cacheExists(name: String) -> Bool {
    let file = urlForCache(named: name)
    return StorageManager.default.fileExists(at: file)
  }
  
  /// Read the cache with the given name to the given message format.
  public func readCache<ProtobufMessage: SwiftProtobuf.Message>(named name: String) throws -> ProtobufMessage {
    guard cacheExists(name: name) else {
      throw CacheError.noSuchCache
    }
    
    let file = urlForCache(named: name)
    let data: Data
    do {
      data = try Data(contentsOf: file)
    } catch {
      log.error("Failed to read cache '\(name)': \(error)")
      throw CacheError.failedToRead
    }
    do {
      let deserialized = try ProtobufMessage(serializedData: data)
      return deserialized
    } catch {
      log.error("Failed to deserialize cache '\(name)': \(error)")
      throw CacheError.failedToDeserialize
    }
  }
  
  /// Write the given protobuf message to the cache with the given name.
  public func writeCache<ProtobufMessage: SwiftProtobuf.Message>(_ cache: ProtobufMessage, named name: String) throws {
    let file = urlForCache(named: name)
    let data: Data
    do {
      data = try cache.serializedData()
    } catch {
      log.error("Failed to serialize cache '\(name)': \(error)")
      throw CacheError.failedToSerialize
    }
    do {
      try data.write(to: file)
    } catch {
      log.error("Failed to write cache '\(name)': \(error)")
      throw CacheError.failedToWrite
    }
  }
}
