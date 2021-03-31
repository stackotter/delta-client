//
//  StartupSequence.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os

class StartupSequence {
  var eventManager: EventManager
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
  }
  
  func run() throws {
    var managers = Managers(eventManager: eventManager)
    
    displayProgress("initialising storage")
    managers.storageManager = try StorageManager()
    managers.cacheManager = try CacheManager(storageManager: managers.storageManager)
    
    displayProgress("reading config")
    managers.configManager = ConfigManager(storageManager: managers.storageManager)
    
    displayProgress(managers.storageManager.isFirstLaunch ? "downloading assets (first launch only)" : "loading assets")
    managers.assetManager = try AssetManager(storageManager: managers.storageManager)
    
    displayProgress("loading textures")
    managers.textureManager = try TextureManager(assetManager: managers.assetManager)
    
    displayProgress(managers.storageManager.isFirstLaunch ? "generating global palette (first launch only)" : "loading global palette from cache")
    managers.blockModelManager = try BlockModelManager(assetManager: managers.assetManager, textureManager: managers.textureManager, cacheManager: managers.cacheManager)
    
    displayProgress("loading locale \(LOCALE)")
    managers.localeManager = LocaleManager(assetManager: managers.assetManager)
    try managers.localeManager.setLocale(to: LOCALE)
    
    eventManager.triggerEvent(.loadingComplete(managers))
  }
  
  func displayProgress(_ message: String) {
    eventManager.triggerEvent(.loadingScreenMessage(message))
  }
}
