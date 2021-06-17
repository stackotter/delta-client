//
//  CacheManager.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import SwiftProtobuf

enum CacheError: LocalizedError {
  case failedToCreateCacheDir(Error)
  case noCacheFor(name: String)
  case failedToDeserialise(name: String, error: Error)
  case failedToSerialise(name: String, error: Error)
  case failedToWriteCache(name: String, error: Error)
}

class CacheManager {
  var storageManager: StorageManager
  var cacheDir: URL
  
  init(storageManager: StorageManager) throws {
    self.storageManager = storageManager
    
    self.cacheDir = self.storageManager.absoluteFromRelative("cache")
    if !self.storageManager.folderExists(at: self.cacheDir) {
      do {
        try self.storageManager.createFolder(atRelativePath: "cache")
      } catch {
        throw CacheError.failedToCreateCacheDir(error)
      }
    }
  }
  
  func urlForCache(name: String) -> URL {
    let file = cacheDir.appendingPathComponent("\(name).bin")
    return file
  }
  
  func cacheExists(name: String) -> Bool {
    let file = urlForCache(name: name)
    return storageManager.fileExists(at: file)
  }
  
  func readCache<ProtobufMessage: SwiftProtobuf.Message>(name: String) throws -> ProtobufMessage {
    guard cacheExists(name: name) else {
      throw CacheError.noCacheFor(name: name)
    }
    let file = urlForCache(name: name)
    do {
      let cache = try ProtobufMessage(serializedData: Data(contentsOf: file))
      return cache
    } catch {
      throw CacheError.failedToDeserialise(name: name, error: error)
    }
  }
  
  func writeCache<ProtobufMessage: SwiftProtobuf.Message>(_ cache: ProtobufMessage, name: String) throws {
    let file = urlForCache(name: name)
    do {
      let data = try cache.serializedData()
      do {
        try data.write(to: file)
      } catch {
        throw CacheError.failedToWriteCache(name: name, error: error)
      }
    } catch {
      throw CacheError.failedToSerialise(name: name, error: error)
    }
  }
}
