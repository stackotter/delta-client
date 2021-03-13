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
  var localeManager: LocaleManager
  
  init() {
    self.init(eventManager: EventManager())
  }
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    self.storageManager = StorageManager()
    self.configManager = ConfigManager(storageManager: self.storageManager)
    self.assetManager = AssetManager(storageManager: self.storageManager)
    self.localeManager = LocaleManager()
  }
}
