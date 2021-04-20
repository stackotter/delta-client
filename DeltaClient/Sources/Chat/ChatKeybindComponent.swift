//
//  ChatKeybindComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct ChatKeybindComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var keybind: String
  
  init(from json: JSON, locale: MinecraftLocale) throws {
    guard let keybind = json.getString(forKey: "keybind") else {
      throw ChatError.noKeybindInJSON
    }
    self.keybind = keybind
    
    siblings = try ChatComponentUtil.readSiblings(json, locale: locale)
    style = ChatComponentUtil.readStyles(json)
  }
  
  func toText() -> String {
    // TODO_LATER: get the relevant keybind from file
    var output = keybind
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
