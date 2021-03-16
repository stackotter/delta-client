//
//  Managers.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation

struct Managers {
  var eventManager: EventManager
  var storageManager: StorageManager
  var configManager: ConfigManager
  var assetManager: AssetManager
  var textureManager: TextureManager
  var blockModelManager: BlockModelManager
  var localeManager: LocaleManager
  
  init() {
    self.init(eventManager: EventManager())
  }
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    self.storageManager = StorageManager()
    self.configManager = ConfigManager(storageManager: self.storageManager)
    self.assetManager = AssetManager(storageManager: self.storageManager)
    self.textureManager = TextureManager(assetManager: self.assetManager)
    self.blockModelManager = BlockModelManager(assetManager: self.assetManager, textureManager: self.textureManager)
    self.localeManager = LocaleManager()
  }
}
