//
//  ChatTranslateComponent.swift
//  DeltaClient
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
  
  init(from json: JSON, locale: MinecraftLocale) throws {
    guard let translateKey = json.getString(forKey: "translate") else {
      throw ChatError.noTranslateKeyInTranslateComponent
    }
    self.translateKey = translateKey
    
    if let withArray = json.getArray(forKey: "with") {
      for elem in withArray {
        let component = try ChatComponentUtil.parseAny(elem, locale: locale)
        content.append(component)
      }
    }
    
    translation = locale.getTranslation(for: translateKey, with: content.map {
      return $0.toText()
    })
    
    siblings = try ChatComponentUtil.readSiblings(json, locale: locale)
    style = ChatComponentUtil.readStyles(json)
  }
  
  func toText() -> String {
    var output = translation
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
