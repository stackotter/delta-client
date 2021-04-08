//
//  ChatStringComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct ChatStringComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var text: String
  
  init(from json: JSON, locale: MinecraftLocale) {
    style = ChatComponentUtil.readStyles(json)
    siblings = ChatComponentUtil.readSiblings(json, locale: locale)
    text = json.getString(forKey: "text")!
  }
  
  init(fromString string: String) {
    text = string
    style = ChatStyle()
    siblings = []
  }
  
  func toText() -> String {
    var output = text
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
