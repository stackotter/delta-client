//
//  ChatScoreComponent.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct ChatScoreComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var name: String
  var objective: String
  var value: String
  
  init(from json: JSON, locale: MinecraftLocale) {
    style = ChatComponentUtil.readStyles(json)
    siblings = ChatComponentUtil.readSiblings(json, locale: locale)
    
    let score = json.getJSON(forKey: "score")!
    name = score.getString(forKey: "name")!
    objective = score.getString(forKey: "objective")!
    value = score.getString(forKey: "value")!
  }
  
  func toText() -> String {
    return "\(name):\(objective):\(value)"
  }
}
