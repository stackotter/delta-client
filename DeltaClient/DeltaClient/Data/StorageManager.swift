//
//  StorageManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os
import Zip

enum StorageError: LocalizedError {
  case applicationSupportMissing
  case failedToCreateDirectory(Error)
  case failedToCreateBackup(Error)
}

class StorageManager {
  var fileManager: FileManager
  var storageDir: URL
  var isFirstLaunch: Bool
  
  init() throws {
    self.fileManager = FileManager.default
    
    if let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      self.storageDir = applicationSupport.appendingPathComponent("DeltaClient")
      
      // attempt to create an application support directory for the client if it doesn't exist
      var isDirectory: ObjCBool = false
      let fileExists = fileManager.fileExists(atPath: self.storageDir.path, isDirectory: &isDirectory)
      if !fileExists || !isDirectory.boolValue {
        Logger.log("creating application support directory")
        do {
          try fileManager.createDirectory(at: self.storageDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
          throw StorageError.failedToCreateDirectory(error)
        }
      }
      
      // check if this is the first launch
      let launchMarker = self.storageDir.appendingPathComponent(".haslaunched")
      self.isFirstLaunch = !self.fileManager.fileExists(atPath: launchMarker.path)
      if self.isFirstLaunch {
        if try! fileManager.contentsOfDirectory(at: self.storageDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).count != 0 {
          try self.createBackup()
        }
        
        self.fileManager.createFile(
          atPath: launchMarker.path,
          contents: "delete this file to reset the client. a backup of this folder is made automatically when resetting.".data(using: .utf8),
          attributes: nil
        )
      }
    } else {
      throw StorageError.applicationSupportMissing
    }
  }
  
  func absoluteFromRelative(_ path: String) -> URL {
    let absoluteURL = storageDir.appendingPathComponent(path)
    return absoluteURL
  }
  
  func fileExists(at url: URL) -> Bool {
    return fileManager.fileExists(atPath: url.path)
  }
  
  func folderExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let fileExists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return fileExists && isDirectory.boolValue
  }
  
  func createFolder(atRelativePath path: String) throws {
    let absoluteURL = absoluteFromRelative(path)
    try createFolder(absoluteURL)
  }
  
  func createFolder(_ url: URL) throws {
    do {
      try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    } catch {
      Logger.error("failed to create directory '\(url)'")
      throw StorageError.failedToCreateDirectory(error)
    }
  }
  
  func createBackup() throws {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH-mm-ss"
    
    let backupName = "backup \(formatter.string(from: date))"
    
    do {
      let destination = try Zip.quickZipFiles(
        [storageDir],
        fileName: backupName
      )
      for item in try fileManager.contentsOfDirectory(at: storageDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
        try fileManager.removeItem(at: item)
      }
      try fileManager.copyItem(at: destination, to: storageDir.appendingPathComponent("\(backupName).zip"))
    } catch {
      throw StorageError.failedToCreateBackup(error)
    }
  }
  
  func getMinecraftFolder() -> URL {
    let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let minecraftFolder = applicationSupportDirectory.appendingPathComponent("minecraft")
    return minecraftFolder
  }
}
