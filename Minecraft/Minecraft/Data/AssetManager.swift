//
//  AssetManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os
import Zip

enum AssetError: LocalizedError {
  case failedToDownload
}

class AssetManager {
  var storageManager: StorageManager
  var assetsFolder: URL
  
  init(storageManager: StorageManager) {
    self.storageManager = storageManager
    self.assetsFolder = self.storageManager.getAssetsFolder()
  }
  
  func checkAssetsExist() -> Bool {
    return storageManager.exists(assetsFolder)
  }
  
  func downloadAssets() -> Bool {
    guard let versionURLsFile = storageManager.getAbsoluteFromRelative("version_urls.json") else {
      return false
    }
    
    // if version_urls.json doesn't exist download the contents from mojang
    if !storageManager.exists(versionURLsFile) {
      Logger.debug("downloading version manifest")
      let versionManifestURL = URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!
      guard let versionManifestJson = try? JSON.fromURL(versionManifestURL) else {
        Logger.error("failed to download version manifest")
        return false
      }
      guard let versionsArray = versionManifestJson.getArray(forKey: "versions") as? [[String: Any]] else {
        Logger.error("failed to parse version manifest")
        return false
      }
      var downloadURLs: [String: String] = [:] // maps versions to download urls
      for versionDict in versionsArray {
        let versionJson = JSON(dict: versionDict)
        guard let version = versionJson.getString(forKey: "id") else {
          Logger.error("failed to parse version manifest")
          return false
        }
        guard let downloadURL = versionJson.getString(forKey: "url") else {
          Logger.error("failed to parse version manifest")
          return false
        }
        downloadURLs[version] = downloadURL
      }
      let outputJson = JSON(dict: downloadURLs)
      if !outputJson.writeTo(versionURLsFile) {
        return false
      }
      Logger.debug("downloaded and processed version manifest")
    }
    
    // download version metadata
    guard let downloadURLs = try? JSON.fromURL(versionURLsFile) else {
      Logger.error("failed to read json from version_urls.json")
      return false
    }
    Logger.debug("downloading client jar metadata")
    guard let downloadURLString = downloadURLs.getString(forKey: "1.16.1") else { // TODO: don't hardcode version
      Logger.error("failed to find download url for version 1.16.1 metadata json")
      return false
    }
    guard let downloadURL = URL(string: downloadURLString) else {
      Logger.error("invalid client metadata download url for version 1.16.1 in version_urls.json")
      return false
    }
    guard let clientVersionMetadata = try? JSON.fromURL(downloadURL) else {
      Logger.error("failed to download 1.16.1 metadata")
      return false
    }
    
    // download client jar
    guard let clientJarURLString = clientVersionMetadata.getJSON(forKey: "downloads")?.getJSON(forKey: "client")?.getString(forKey: "url") else {
      Logger.error("invalid version json for 1.16.1")
      return false
    }
    guard let clientJarURL = URL(string: clientJarURLString) else {
      Logger.error("invalid client jar download url")
      return false
    }
    
    let clientJar = FileManager.default.temporaryDirectory.appendingPathComponent("1.16.1-client.jar")
    let clientJarExtracted = FileManager.default.temporaryDirectory.appendingPathComponent("1.16.1-client", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: clientJarExtracted, withIntermediateDirectories: true, attributes: nil)
    } catch {
      Logger.error("failed to create output directory for extracting client jar")
      return false
    }
    do {
      print(clientJarURL)
      Logger.debug("downloading client jar..")
      let clientJarData = try Data(contentsOf: clientJarURL)
      try clientJarData.write(to: clientJar)
    } catch {
      Logger.error("failed to download client jar")
      return false
    }
    Logger.debug("extracting client jar")
    do {
      Zip.addCustomFileExtension("jar")
      try Zip.unzipFile(clientJar, destination: clientJarExtracted, overwrite: true, password: nil)
    } catch {
      Logger.error("failed to extract client jar with error: \(error)")
      return false
    }
    Logger.debug("extracted client jar")
    
    do {
      try FileManager.default.copyItem(at: clientJarExtracted.appendingPathComponent("assets"), to: assetsFolder)
    } catch {
      Logger.error("failed to copy assets to application support")
      return false
    }
    return true
  }
  
  func getLocaleURL(withName localeName: String) -> URL? {
    let localeURL = assetsFolder.appendingPathComponent("minecraft/lang/\(localeName).json")
    if storageManager.exists(localeURL) {
      return localeURL
    }
    return nil
  }
}
