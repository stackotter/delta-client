//
//  StartupSequence.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os

enum StartupError: LocalizedError {
  case failedToDownloadAssets
  case missingLocale
  case failedToDownloadPixlyzerData(AssetError?)
  case failedToLoadLocale(LocaleError?)
  case failedToLoadBlockModels(BlockModelError?)
  case failedToLoadGlobalBlockPalette(BlockModelError?)
  case failedToLoadBlockTextures(TextureError?)
}

// TODO: make the managers' inits throw so less optionals are needed for things and errors are picked up early. use hashes to check whether assets need to be re-verified or anything
// TODO: make a verify function and a repair function for storage and asset manager and things like that
class StartupSequence {
  var eventManager: EventManager
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
  }
  
  func run() throws {
    // initialise managers
    eventManager.triggerEvent(.loadingScreenMessage("initialising managers"))
    let managers = Managers(eventManager: eventManager)
    
    // download assets if neccessary
    if !managers.assetManager.checkAssetsExist() {
      eventManager.triggerEvent(.loadingScreenMessage("downloading and extracting assets (this only happens once, it shouldn't take too long, only 18mb)"))
      let success = managers.assetManager.downloadAssets()
      if !success {
        throw StartupError.failedToDownloadAssets
      }
      Logger.log("successfully downloaded assets")
    } else {
      Logger.log("assets exist")
    }
    
    // download pixlyzer data
    if !managers.assetManager.checkPixlyzerDataExists() {
      eventManager.triggerEvent(.loadingScreenMessage("downloading pixlyzer data (this only happens once, it shouldn't take too long, only 12mb"))
      do {
        try managers.assetManager.downloadPixlyzerData()
      } catch {
        throw StartupError.failedToDownloadPixlyzerData(error as? AssetError)
      }
      Logger.log("downloaded pixlyzer data")
    }
    
    // load block textures
    eventManager.triggerEvent(.loadingScreenMessage("loading block textures"))
    do {
      try managers.textureManager.loadBlockTextures()
    } catch {
      throw StartupError.failedToLoadBlockTextures(error as? TextureError)
    }
    Logger.log("successfully loaded block textures")
    
    // load global palette
    eventManager.triggerEvent(.loadingScreenMessage("loading global palette"))
    do {
      try managers.blockModelManager.loadGlobalPalette()
    } catch {
      throw StartupError.failedToLoadGlobalBlockPalette(error as? BlockModelError)
    }
    Logger.log("successfully loaded global palette")
    
    // load locale
    eventManager.triggerEvent(.loadingScreenMessage("loading locale 'en_us'.."))
    guard let localeURL = managers.assetManager.getLocaleURL(withName: "en_us") else {
      throw StartupError.missingLocale
    }
    do {
      try managers.localeManager.addLocale(fromFile: localeURL, withName: "en_us")
      try managers.localeManager.setLocale(to: "en_us")
    } catch {
      throw StartupError.failedToLoadLocale(error as? LocaleError)
    }
    Logger.log("successfully loaded locale")
    
    eventManager.triggerEvent(.loadingComplete(managers))
  }
}
