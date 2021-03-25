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
  case failedToCreateFolder
  case pixlyzerDownloadFailed
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
  
  func checkPixlyzerDataExists() -> Bool {
    return storageManager.exists(storageManager.storageURL.appendingPathComponent("pixlyzer-data"))
  }
  
  func downloadPixlyzerData() throws {
    let pixlyzerDataFolder = storageManager.storageURL.appendingPathComponent("pixlyzer-data")
    if !storageManager.exists(pixlyzerDataFolder) {
      do {
        try storageManager.fileManager.createDirectory(at: pixlyzerDataFolder, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Logger.error("failed to create pixlyzer data folder: \(error)")
        throw AssetError.failedToCreateFolder
      }
    }
    let blockPaletteFile = pixlyzerDataFolder.appendingPathComponent("blocks.json")
    let blockPaletteURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(VERSION_STRING)/blocks.json")!
    let blockPaletteJSON = try Data(contentsOf: blockPaletteURL)
    guard (try? blockPaletteJSON.write(to: blockPaletteFile)) != nil else {
      Logger.error("failed to download pixlyzer block palette")
      throw AssetError.pixlyzerDownloadFailed
    }
  }
  
  // TODO: make download assets a throwing function
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
    guard let downloadURLString = downloadURLs.getString(forKey: VERSION_STRING) else {
      Logger.error("failed to find download url for version \(VERSION_STRING) metadata json")
      return false
    }
    guard let downloadURL = URL(string: downloadURLString) else {
      Logger.error("invalid client metadata download url for version \(VERSION_STRING) in version_urls.json")
      return false
    }
    guard let clientVersionMetadata = try? JSON.fromURL(downloadURL) else {
      Logger.error("failed to download \(VERSION_STRING) metadata")
      return false
    }
    
    // download client jar
    guard let clientJarURLString = clientVersionMetadata.getJSON(forKey: "downloads")?.getJSON(forKey: "client")?.getString(forKey: "url") else {
      Logger.error("invalid version json for \(VERSION_STRING)")
      return false
    }
    guard let clientJarURL = URL(string: clientJarURLString) else {
      Logger.error("invalid client jar download url")
      return false
    }
    
    let clientJar = FileManager.default.temporaryDirectory.appendingPathComponent("\(VERSION_STRING)-client.jar")
    let clientJarExtracted = FileManager.default.temporaryDirectory.appendingPathComponent("\(VERSION_STRING)-client", isDirectory: true)
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
  
  // TODO: make the below functions throwing
  func getBlockModelFolder() -> URL? {
    let blockModelFolder = assetsFolder.appendingPathComponent("minecraft/models/block")
    if storageManager.exists(blockModelFolder) {
      return blockModelFolder
    }
    return nil
  }
  
  func getBlockModelJSON(for identifier: Identifier) throws -> JSON {
    let fileName = "\(identifier.name.split(separator: "/")[1]).json"
    let url = getBlockModelFolder()!.appendingPathComponent(fileName)
    return try JSON.fromURL(url)
  }
  
  func getBlockStatesFolder() -> URL? {
    let blockStatesFolder = assetsFolder.appendingPathComponent("minecraft/blockstates")
    if storageManager.exists(blockStatesFolder) {
      return blockStatesFolder
    }
    return nil
  }
  
  func getBlockTexturesFolder() -> URL? {
    let blockTexturesFolder = assetsFolder.appendingPathComponent("minecraft/textures/block")
    if storageManager.exists(blockTexturesFolder) {
      return blockTexturesFolder
    }
    return nil
  }
  
  func getPixlyzerFolder() -> URL? {
    let pixlyzerFolder = storageManager.storageURL.appendingPathComponent("pixlyzer-data")
    if storageManager.exists(pixlyzerFolder) {
      return pixlyzerFolder
    }
    return nil
  }
}
