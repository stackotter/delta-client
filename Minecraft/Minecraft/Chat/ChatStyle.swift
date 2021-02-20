//
//  ChatStyle.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 16/2/21.
//

import Foundation

struct ChatStyle {
  var bold: Bool = false
  var italic: Bool = false
  var underlined: Bool = false
  var strikethrough: Bool = false
  var obfuscated: Bool = false
  var color: String = "white"
  
  init() {}
  
  init(from json: JSON) {
    bold = json.getBool(forKey: "bold") ?? bold
    italic = json.getBool(forKey: "bold") ?? italic
    underlined = json.getBool(forKey: "bold") ?? underlined
    strikethrough = json.getBool(forKey: "bold") ?? strikethrough
    obfuscated = json.getBool(forKey: "bold") ?? obfuscated
    color = json.getString(forKey: "color") ?? color
  }
}
