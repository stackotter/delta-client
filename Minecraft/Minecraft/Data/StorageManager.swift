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
  var fileManager = FileManager.default
  var storageURL: URL
  
  init() {
    storageURL = StorageManager.getStorageURL()! // TODO: figure out what to do if get storage url fails
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
  
  func getAssetsFolder() -> URL {
    let assetsFolderPath = getAbsoluteFromRelative("assets")!
    return assetsFolderPath
  }
  
  func getCacheFile(name: String) -> URL? {
    let cacheFolder = getAbsoluteFromRelative("cache")!
    let file = cacheFolder.appendingPathComponent(name)
    if exists(file) {
      return file
    }
    return nil
  }
  
  func exists(_ url: URL) -> Bool {
    return fileManager.fileExists(atPath: url.path)
  }
  
  func getFile(atRelativePath path: String) -> URL? {
    guard let absoluteURL = getAbsoluteFromRelative(path) else {
      return nil
    }
    let fileExists = fileManager.fileExists(atPath: absoluteURL.path)
    return fileExists ? absoluteURL : nil
  }
  
  func getFolder(atRelativePath path: String) -> URL? {
    guard let absoluteURL = getAbsoluteFromRelative(path) else {
      return nil
    }
    var isDirectory: ObjCBool = false
    let folderExists = fileManager.fileExists(atPath: absoluteURL.path, isDirectory: &isDirectory)
    
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
      try fileManager.createDirectory(at: absoluteURL, withIntermediateDirectories: true, attributes: nil)
    } catch {
      Logger.error("failed to create directory at relative path `\(path)`")
      return false
    }
    return true
  }
  
  func getBundledResourceByName(_ name: String, fileExtension: String) -> URL? {
    guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
      Logger.debug("failed to find bundled resource with '\(name).\(fileExtension)'")
      return nil
    }
    return url
  }
  
  func getAbsoluteFromRelative(_ path: String) -> URL? {
    let absoluteURL = storageURL.appendingPathComponent(path)
    return absoluteURL
  }
  
  func getMinecraftFolder() -> URL? {
    let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let minecraftFolder = applicationSupportDirectory.appendingPathComponent("minecraft")
    return minecraftFolder
  }
}
