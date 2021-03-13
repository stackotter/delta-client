//
//  LocaleManager.swift
//  Minecraft
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
  private var locales: [String: MinecraftLocale]
  var currentLocaleName: String?
  var currentLocale: MinecraftLocale {
    if let name = currentLocaleName {
      return locales[name] ?? MinecraftLocale()
    }
    return MinecraftLocale()
  }
  
  init() {
    self.locales = [:]
    self.currentLocaleName = nil
  }
  
  func addLocale(fromFile file: URL, withName name: String) throws {
    guard let locale = try? MinecraftLocale(localeFile: file) else {
      Logger.error("failed to add locale")
      throw LocaleError.badLocaleFile
    }
    locales[name] = locale
  }
  
  func setLocale(to localeName: String) throws {
    if locales.keys.contains(localeName) {
      currentLocaleName = localeName
    } else {
      throw LocaleError.invalidLocale
    }
  }
}
