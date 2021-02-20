//
//  ChatTranslateComponent.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 17/2/21.
//

import Foundation

struct ChatTranslateComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var translateKey: String
  var translation: String
  var content: [ChatComponent] = []
  
  init(from json: JSON, locale: MinecraftLocale) {
    style = ChatComponentUtil.readStyles(json)
    siblings = ChatComponentUtil.readSiblings(json, locale: locale)
    translateKey = json.getString(forKey: "translate")!
    if json.containsKey("with") {
      let withArray = json.getArray(forKey: "with")!
      for elem in withArray {
        let component = ChatComponentUtil.parseAny(elem, locale: locale)
        if component != nil {
          content.append(component!)
        }
      }
    }
    translation = locale.getTranslation(for: translateKey, with: content.map {
      return $0.toText()
    })
  }
  
  func toText() -> String {
    var output = translation
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
