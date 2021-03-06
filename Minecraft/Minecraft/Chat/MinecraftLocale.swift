//
//  MinecraftLocale.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation
import os

struct MinecraftLocale {
  var translations: [String: String]
  
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
    let regex = try! NSRegularExpression(pattern: "(^%s)|([^%](%s))") // i know this regex won't fail to load because it's statice, that's why i use try!
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
  
  static func get(_ lang: String) -> MinecraftLocale? {
    do {
      if let fileURL = Bundle.main.url(forResource: "en_us", withExtension: ".json") {
        let data = try Data(contentsOf: fileURL)
        if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
          return MinecraftLocale(translations: dict)
        } else {
          Logger.warning("failed to parse contents of \(lang).json")
        }
      }
      Logger.warning("locale \(lang) does not exist")
      return nil
    } catch {
      Logger.warning("failed to read locale file \(lang).json")
      return nil
    }
  }
  
  static func empty() -> MinecraftLocale {
    return MinecraftLocale(translations: [:])
  }
}
