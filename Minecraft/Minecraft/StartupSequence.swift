//
//  StartupSequence.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os

enum StartupError: LocalizedError {
  case missingLocale
}

class StartupSequence {
  var eventManager: EventManager
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
  }
  
  func run() throws {
    eventManager.triggerEvent(.loadingScreenMessage("starting storage and asset managers"))
    let storageManager = StorageManager()
    let assetManager = AssetManager(storageManager: storageManager)
    if !assetManager.checkAssetsExist() {
      eventManager.triggerEvent(.loadingScreenMessage("downloading assets.. (this is a one time thing)"))
      let success = assetManager.downloadAssets()
      if !success {
        Logger.error("failed to download assets")
        throw AssetError.failedToDownload
      }
      Logger.debug("successfully downloaded assets")
    } else {
      Logger.debug("assets exist")
    }
    eventManager.triggerEvent(.loadingScreenMessage("loading locale 'en_us'.."))
    let localeManager = LocaleManager()
    guard let localeURL = assetManager.getLocaleURL(withName: "en_us") else {
      throw StartupError.missingLocale
    }
    do {
      try localeManager.addLocale(fromFile: localeURL, withName: "en_us")
      try localeManager.setLocale(to: "en_us")
    } catch {
      Logger.error("failed to load locale")
      throw error
    }
    Logger.debug("successfully loaded locale")
    
    let managers = Managers(eventManager: eventManager, storageManager: storageManager, assetManager: assetManager, localeManager: localeManager)
    eventManager.triggerEvent(.loadingComplete(managers))
  }
}
