//
//  StorageManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/6/21.
//

import Foundation

/// A manager that provides all of the functionality DeltaClient needs to interact with the file system.
class StorageManager {
  static var `default` = StorageManager()
  
  public let isFirstLaunch: Bool
  
  private var fileManager = FileManager.default
  private var storageDirectory: URL
  
  private init() {
    // Get the url of the storage directory
    if let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      storageDirectory = applicationSupport.appendingPathComponent("dev.stackotter.delta-client")
    } else {
      DeltaClientApp.modalWarning("Failed to get application support directory, using temporary directory instead")
      let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("dev.stackotter.delta-client.fallback")
      storageDirectory = fallback
    }
    
    let storagePath = storageDirectory.path
    log.debug("Using \(storagePath) as storage directory")
    
    // Create the storage directory if required
    var isDirectory: ObjCBool = false
    let fileExists = fileManager.fileExists(atPath: storageDirectory.path, isDirectory: &isDirectory)
    do {
      if !fileExists {
        log.info("Creating application support directory")
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
      } else if !isDirectory.boolValue {
        log.warning("Application support directory was file instead of directory. Replacing with directory.")
        try fileManager.removeItem(at: storageDirectory)
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
      }
    } catch {
      fatalError("Failed to create storage directory: \(error)")
    }
    
    // Check if this is a fresh launch of the app
    let launchMarker = self.storageDirectory.appendingPathComponent(".haslaunched")
    self.isFirstLaunch = !self.fileManager.fileExists(atPath: launchMarker.path)
    if self.isFirstLaunch {
      // Backup the current contents of the directory in case this a forced fresh install
      do {
        try self.createBackup()
        try self.resetStorage()
      } catch {
        fatalError("Failed to reset storage for fresh install: \(error)")
      }
      
      // Create the launch marker
      self.fileManager.createFile(
        atPath: launchMarker.path,
        contents: nil,
        attributes: nil
      )
    }
  }
  
  /// Returns the absolute URL of a path relative to the storage directory.
  func absoluteFromRelative(_ relativePath: String) -> URL {
    return storageDirectory.appendingPathComponent(relativePath)
  }
  
  /// Create a zip backup of the storage directory.
  func createBackup() throws {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH-mm-ss"
    
    let backupName = "backup \(formatter.string(from: date))"
    let backupFile = absoluteFromRelative("\(backupName).zip")
    
    do {
      try fileManager.zipItem(at: storageDirectory, to: backupFile)
    } catch {
      throw StorageError.failedToCreateBackup(error)
    }
  }
  
  /// Reset the application support storage directory's content
  private func resetStorage() throws {
    for item in try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
      if !item.lastPathComponent.hasPrefix("backup") {
        try fileManager.removeItem(at: item)
      }
    }
  }
}
