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
  var assetManager: AssetManager
  var localeManager: LocaleManager
  
  init(eventManager: EventManager, storageManager: StorageManager, assetManager: AssetManager, localeManager: LocaleManager) {
    self.eventManager = eventManager
    self.storageManager = storageManager
    self.assetManager = assetManager
    self.localeManager = localeManager
  }
  
  init() {
    self.eventManager = EventManager()
    self.storageManager = StorageManager()
    self.assetManager = AssetManager(storageManager: self.storageManager)
    self.localeManager = LocaleManager()
  }
}
