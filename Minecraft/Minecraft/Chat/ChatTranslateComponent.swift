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
  var with: [ChatComponent] = []
  
  init(from json: JSON) {
    style = ChatComponentUtil.readStyles(json)
    siblings = ChatComponentUtil.readSiblings(json)
    translateKey = json.getString(forKey: "translate")!
    if json.containsKey("with") {
      let withArray = json.getArray(forKey: "with")!
      for elem in withArray {
        let component = ChatComponentUtil.parseAny(elem)
        if component != nil {
          with.append(component!)
        }
      }
    }
  }
  
  func toText() -> String {
    // IMPLEMENT: actually using the template for the key
    return translateKey
  }
}
