//
//  StorageManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os
import Zip

class StorageManager {
  init() {
    
  }
  
  func getMojangAssetsFolder() -> URL {
    let assetsFolderPath = getAbsoluteFromRelative("assets")!
    return assetsFolderPath
  }
  
  func exists(_ url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
  }
  
  func getFile(atRelativePath path: String) -> URL? {
    guard let absoluteURL = getAbsoluteFromRelative(path) else {
      return nil
    }
    let fileExists = FileManager.default.fileExists(atPath: absoluteURL.path)
    return fileExists ? absoluteURL : nil
  }
  
  func getFolder(atRelativePath path: String) -> URL? {
    guard let absoluteURL = getAbsoluteFromRelative(path) else {
      return nil
    }
    var isDirectory: ObjCBool = false
    let folderExists = FileManager.default.fileExists(atPath: absoluteURL.path, isDirectory: &isDirectory)
    
    if !isDirectory.boolValue || !folderExists {
      return nil
    }
    
    return absoluteURL
  }
  
  func createFolder(atRelativePath path: String) -> Bool {
    guard let absoluteURL = getAbsoluteFromRelative(path) else {
      return false
    }
    do {
      try FileManager.default.createDirectory(at: absoluteURL, withIntermediateDirectories: true, attributes: nil)
    } catch {
      Logger.error("failed to create directory at relative path `\(path)`")
      return false
    }
    return true
  }
  
  func getAbsoluteFromRelative(_ path: String) -> URL? {
    guard let storageURL = StorageManager.getStorageURL() else {
      return nil
    }
    let absoluteURL = storageURL.appendingPathComponent(path)
    return absoluteURL
  }
  
  static func getStorageURL() -> URL? {
    let fileManager = FileManager.default
    var applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    applicationSupportDirectory.appendPathComponent("MinecraftSwiftEdition")
    
    var isDirectory: ObjCBool = false
    let folderExists = fileManager.fileExists(atPath: applicationSupportDirectory.path, isDirectory: &isDirectory)
    
    if !isDirectory.boolValue || !folderExists {
      do {
        try fileManager.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Logger.error("failed to create application support directory")
        return nil
      }
    }
    
    return applicationSupportDirectory
  }
}
