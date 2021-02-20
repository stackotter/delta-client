//
//  ChatKeybindComponent.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct ChatKeybindComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var keybind: String
  
  init(from json: JSON, locale: MinecraftLocale) {
    style = ChatComponentUtil.readStyles(json)
    siblings = ChatComponentUtil.readSiblings(json, locale: locale)
    keybind = json.getString(forKey: "keybind")!
  }
  
  func toText() -> String {
    // IMPLEMENT: get the relevant keybind from file
    return keybind
  }
}
