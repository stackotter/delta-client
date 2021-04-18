//
//  StartupSequence.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os

class StartupSequence {
  func run() throws {
    var managers = Managers()
    
    displayProgress("initialising storage")
    managers.storageManager = try StorageManager()
    managers.cacheManager = try CacheManager(storageManager: managers.storageManager)
    
    displayProgress("reading config")
    managers.configManager = try ConfigManager(storageManager: managers.storageManager)
    
    displayProgress(managers.storageManager.isFirstLaunch ? "downloading assets (first launch only)" : "loading assets")
    managers.assetManager = try AssetManager(storageManager: managers.storageManager)
    
    displayProgress("loading textures")
    managers.textureManager = try TextureManager(assetManager: managers.assetManager)
    
    displayProgress(managers.storageManager.isFirstLaunch ? "generating global palette (first launch only)" : "loading global palette from cache")
    managers.blockPaletteManager = try BlockPaletteManager(assetManager: managers.assetManager, textureManager: managers.textureManager, cacheManager: managers.cacheManager)
    
    displayProgress("loading locale \(Constants.locale)")
    managers.localeManager = LocaleManager(assetManager: managers.assetManager)
    try managers.localeManager.setLocale(to: Constants.locale)
    
    DeltaClientApp.eventManager.triggerEvent(.loadingComplete(managers))
  }
  
  func displayProgress(_ message: String) {
    DeltaClientApp.eventManager.triggerEvent(.loadingScreenMessage(message))
  }
}
