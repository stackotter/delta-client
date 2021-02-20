//
//  ChatComponentUtil.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation
import os

struct ChatComponentUtil {
  static func parseJSON(_ json: JSON, locale: MinecraftLocale) -> ChatComponent? {
    if json.containsKey("text") {
      return ChatStringComponent(from: json, locale: locale)
    } else if json.containsKey("translate") {
      return ChatTranslateComponent(from: json, locale: locale)
    } else if json.containsKey("keybind") {
      return ChatKeybindComponent(from: json, locale: locale)
    } else if json.containsKey("score") {
      return ChatScoreComponent(from: json, locale: locale)
    } else {
      Logger.warning("server sent invalid chat component")
      return nil
    }
  }
  
  static func parseAny(_ object: Any, locale: MinecraftLocale) -> ChatComponent? {
    if let string = object as? String {
      let component = ChatStringComponent(fromString: string)
      return component
    } else if let dict = object as? [String: Any] {
      let component = ChatComponentUtil.parseJSON(JSON(dict: dict), locale: locale)
      return component
    } else if let array = object as? [Any] {
      let component = ChatComponentUtil.parseAny(array[0], locale: locale)
      guard var parent = component else {
        Logger.warning("failed to read array chat component. invalid parent component")
        return nil
      }
      parent.siblings = readSiblingsArray(array: [Any](array.dropFirst()), locale: locale)
      return parent
    }
    Logger.warning("failed to ready chat component (invalid type)")
    return nil
  }
  
  static func readSiblings(_ json: JSON, locale: MinecraftLocale) -> [ChatComponent] {
    if let extra = json.getArray(forKey: "extra") {
      return readSiblingsArray(array: extra, locale: locale)
    }
    return []
  }
  
  static func readSiblingsArray(array: [Any], locale: MinecraftLocale) -> [ChatComponent] {
    var sibs: [ChatComponent] = []
    for sibling in array {
      let component = ChatComponentUtil.parseAny(sibling, locale: locale)
      if component != nil {
        sibs.append(component!)
      }
    }
    
    return sibs
  }
  
  static func readStyles(_ json: JSON) -> ChatStyle {
    return ChatStyle(from: json)
  }
}
