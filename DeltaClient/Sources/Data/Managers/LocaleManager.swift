//
//  LocaleManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import os

enum LocaleError: LocalizedError {
  case invalidLocale
  case badLocaleFile
}

class LocaleManager {
  var assetManager: AssetManager
  
  private var locales: [String: MinecraftLocale] = [:]
  
  var currentLocaleName: String? = nil
  var currentLocale: MinecraftLocale {
    if let name = currentLocaleName {
      return locales[name] ?? MinecraftLocale()
    }
    return MinecraftLocale()
  }
  
  init(assetManager: AssetManager) {
    self.assetManager = assetManager
  }
  
  func addLocale(fromFile file: URL, withName name: String) throws {
    guard let locale = try? MinecraftLocale(localeFile: file) else {
      Logger.error("failed to add locale")
      throw LocaleError.badLocaleFile
    }
    locales[name] = locale
  }
  
  func setLocale(to localeName: String) throws {
    guard let localeFile = try? assetManager.getLocaleURL(withName: localeName) else {
      throw LocaleError.invalidLocale
    }
    try addLocale(fromFile: localeFile, withName: localeName)
    currentLocaleName = localeName
  }
}
