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
    bold = json.getBoolString(forKey: "bold") ?? bold
    italic = json.getBoolString(forKey: "bold") ?? italic
    underlined = json.getBoolString(forKey: "bold") ?? underlined
    strikethrough = json.getBoolString(forKey: "bold") ?? strikethrough
    obfuscated = json.getBoolString(forKey: "bold") ?? obfuscated
    color = json.getString(forKey: "color") ?? color
  }
}
