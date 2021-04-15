//
//  AssetManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os
import Zip

enum AssetError: LocalizedError {
  case assetsDownloadFailed(Error)
  case pixlyzerDownloadFailed(Error)
  case manifestDownloadFailed(Error)
  case failedToParseManifest
  case failedToWriteVersionURLs
  case noURLForVersion(String)
  case invalidMetadataURL(version: String, url: String)
  case invalidVersionMetadata
  case invalidClientJarURL(url: String)
  case failedToDownloadClientJar(Error)
  case failedToExtractClientJar(Error)
  case invalidLocale(String)
  case noModelsFolder
  case noBlockTexturesFolder
}

class AssetManager {
  var storageManager: StorageManager
  var assetsFolder: URL
  var pixlyzerFolder: URL
  
  init(storageManager: StorageManager) throws {
    self.storageManager = storageManager
    self.assetsFolder = self.storageManager.absoluteFromRelative("assets")
    self.pixlyzerFolder = self.storageManager.absoluteFromRelative("pixlyzer-data")
    
    if !self.storageManager.folderExists(at: self.assetsFolder) {
      try downloadAssets()
    }
    
    if !self.storageManager.folderExists(at: self.pixlyzerFolder) {
      try downloadPixlyzerData()
    }
  }
  
  func downloadAssets() throws {
    // if version_urls.json doesn't exist download the contents from mojang
    let versionURLsFile = storageManager.absoluteFromRelative("version_urls.json")
    if !storageManager.fileExists(at: versionURLsFile) {
      Logger.log("downloading versions manifest")
      try downloadVersionURLs()
      Logger.log("downloaded versions manifest")
    }
    let downloadURLs = try JSON.fromURL(versionURLsFile)
    
    // download version metadata
    Logger.log("downloading client jar metadata")
    guard let downloadURLString = downloadURLs.getString(forKey: VERSION_STRING) else {
      Logger.error("failed to find download url for version \(VERSION_STRING) metadata json")
      throw AssetError.noURLForVersion(VERSION_STRING)
    }
    guard let downloadURL = URL(string: downloadURLString) else {
      Logger.error("invalid client metadata download url for version \(VERSION_STRING) in version_urls.json")
      throw AssetError.invalidMetadataURL(version: VERSION_STRING, url: downloadURLString)
    }
    let clientVersionMetadata = try JSON.fromURL(downloadURL)
    
    // get client jar download url
    guard let clientJarURLString = clientVersionMetadata.getJSON(forKey: "downloads")?.getJSON(forKey: "client")?.getString(forKey: "url") else {
      Logger.error("invalid version json for \(VERSION_STRING)")
      throw AssetError.invalidVersionMetadata
    }
    guard let clientJarURL = URL(string: clientJarURLString) else {
      Logger.error("invalid client jar download url")
      throw AssetError.invalidClientJarURL(url: clientJarURLString)
    }
    
    // download and extract the client jar
    let clientJar = FileManager.default.temporaryDirectory.appendingPathComponent("client.jar")
    let clientJarExtracted = FileManager.default.temporaryDirectory.appendingPathComponent("client", isDirectory: true)
    try FileManager.default.createDirectory(at: clientJarExtracted, withIntermediateDirectories: true, attributes: nil)
    do {
      Logger.debug("downloading client jar..")
      let clientJarData = try Data(contentsOf: clientJarURL)
      try clientJarData.write(to: clientJar)
    } catch {
      Logger.error("failed to download client jar")
      throw AssetError.failedToDownloadClientJar(error)
    }
    Logger.log("extracting client jar")
    do {
      Zip.addCustomFileExtension("jar")
      try Zip.unzipFile(clientJar, destination: clientJarExtracted, overwrite: true, password: nil)
    } catch {
      Logger.error("failed to extract client jar with error: \(error)")
      throw AssetError.failedToExtractClientJar(error)
    }
    Logger.debug("extracted client jar")
    
    // copy assets from extracted jar to application support
    try FileManager.default.copyItem(at: clientJarExtracted.appendingPathComponent("assets"), to: assetsFolder)
  }
  
  func downloadPixlyzerData() throws {
    try storageManager.createFolder(pixlyzerFolder)
    let blockPaletteFile = pixlyzerFolder.appendingPathComponent("blocks.json")
    
    let blockPaletteURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(VERSION_STRING)/blocks.json")!
    let blockPaletteJSON = try Data(contentsOf: blockPaletteURL)
    
    do {
      try blockPaletteJSON.write(to: blockPaletteFile)
    } catch {
      Logger.error("failed to download pixlyzer block palette")
      throw AssetError.pixlyzerDownloadFailed(error)
    }
  }
  
  func downloadVersionURLs() throws {
    let versionURLsFile = storageManager.absoluteFromRelative("version_urls.json")
    let versionManifestURL = URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!
    do {
      let versionManifestJson = try JSON.fromURL(versionManifestURL)
      guard let versionsArray = versionManifestJson.getArray(forKey: "versions") as? [[String: Any]] else {
        Logger.error("failed to parse version manifest")
        throw AssetError.failedToParseManifest
      }
      var downloadURLs: [String: String] = [:] // maps versions to download urls
      for versionDict in versionsArray {
        let versionJson = JSON(dict: versionDict)
        
        guard let version = versionJson.getString(forKey: "id"),
              let downloadURL = versionJson.getString(forKey: "url") else {
          Logger.error("failed to parse version manifest")
          throw AssetError.failedToParseManifest
        }
        downloadURLs[version] = downloadURL
        
        let outputJson = JSON(dict: downloadURLs)
        if !outputJson.writeTo(versionURLsFile) {
          throw AssetError.failedToWriteVersionURLs
        }
      }
    } catch {
      Logger.error("failed to download/process version manifest: error")
      throw AssetError.manifestDownloadFailed(error)
    }
  }
  
  func getLocaleURL(withName localeName: String) throws -> URL {
    let localeURL = assetsFolder.appendingPathComponent("minecraft/lang/\(localeName).json")
    guard storageManager.fileExists(at: localeURL) else {
      throw AssetError.invalidLocale(localeName)
    }
    return localeURL
  }
  
  func getModelsFolder() throws -> URL {
    let modelsFolder = assetsFolder.appendingPathComponent("minecraft/models")
    guard storageManager.folderExists(at: modelsFolder) else {
      throw AssetError.noModelsFolder
    }
    return modelsFolder
  }
  
  func getModelJSON(for identifier: Identifier) throws -> JSON {
    let fileName = "\(identifier.name).json"
    let url = try getModelsFolder().appendingPathComponent(fileName)
    return try JSON.fromURL(url)
  }
  
  func getBlockTexturesFolder() throws -> URL {
    let blockTexturesFolder = assetsFolder.appendingPathComponent("minecraft/textures/block")
    guard storageManager.folderExists(at: blockTexturesFolder) else {
      throw AssetError.noBlockTexturesFolder
    }
    return blockTexturesFolder
  }
  
  func getPixlyzerFolder() -> URL {
    return pixlyzerFolder
  }
}
