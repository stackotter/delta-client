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
    // initialise managers
    eventManager.triggerEvent(.loadingScreenMessage("initialising managers"))
    let managers = Managers(eventManager: eventManager)
    
    // start asset manager and download assets if neccessary
    eventManager.triggerEvent(.loadingScreenMessage("starting asset manager"))
    if !managers.assetManager.checkAssetsExist() {
      eventManager.triggerEvent(.loadingScreenMessage("downloading and extracting assets (this only happens once, it shouldn't take too long, only 18mb)"))
      let success = managers.assetManager.downloadAssets()
      if !success {
        Logger.error("failed to download assets")
        throw AssetError.failedToDownload
      }
      Logger.debug("successfully downloaded assets")
    } else {
      Logger.debug("assets exist")
    }
    
    // load locale
    eventManager.triggerEvent(.loadingScreenMessage("loading locale 'en_us'.."))
    guard let localeURL = managers.assetManager.getLocaleURL(withName: "en_us") else {
      throw StartupError.missingLocale
    }
    do {
      try managers.localeManager.addLocale(fromFile: localeURL, withName: "en_us")
      try managers.localeManager.setLocale(to: "en_us")
    } catch {
      Logger.error("failed to load locale")
      throw error
    }
    Logger.debug("successfully loaded locale")
    
    eventManager.triggerEvent(.loadingComplete(managers))
  }
}
