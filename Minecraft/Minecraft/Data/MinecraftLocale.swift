//
//  LocaleManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation
import os

enum MinecraftLocaleError: LocalizedError {
  case unableToParseLocale
}

// TODO: clean up Locale stuff
struct MinecraftLocale {
  var translations: [String: String]
  var currentLocaleFile: URL?
  
  init(localeFile: URL) throws {
    do {
      let data = try Data(contentsOf: localeFile) // relies on the caller checking that file exists
      if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
        self.translations = dict
        self.currentLocaleFile = localeFile
        return
      }
    } catch {
      Logger.error("failed to parse locale `\(localeFile.lastPathComponent)`")
      throw error
    }
    throw MinecraftLocaleError.unableToParseLocale
  }
  
  init() {
    self.translations = [:]
    self.currentLocaleFile = nil
  }
  
  func getTranslation(for key: String) -> String {
    if let translation = translations[key] {
      return translation
    } else {
      return key
    }
  }
  
  // TODO: just use string.format instead of this regex stuff because otherwise %1$s doesn't work and stuff
  func getTranslation(for key: String, with content: [String]) -> String {
    let template = getTranslation(for: key)
    let regex = try! NSRegularExpression(pattern: "(^%s)|([^%](%s))") // i know this regex won't fail to load because it's static, that's why i use try!
    let matches = regex.matches(in: template, range: NSRange(location: 0, length: template.count))
    
    let ranges: [Range<String.Index>] = matches.map {
      var range = $0.range
      if range.length == 3 {
        range.location += 1
        range.length -= 1
      }
      return Range(range, in: template)!
    }
    
    if ranges.count != content.count {
      return "failed to use translation template: \(template). incorrect number of arguments"
    }
    
    var output = template
    for i in (0..<ranges.count).reversed() {
      output.replaceSubrange(ranges[i], with: content[i])
    }
    return output
  }
}
