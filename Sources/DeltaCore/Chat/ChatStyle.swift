//
//  ChatStyle.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/2/21.
//

import Foundation

public struct ChatStyle {
  public var bold: Bool = false
  public var italic: Bool = false
  public var underlined: Bool = false
  public var strikethrough: Bool = false
  public var obfuscated: Bool = false
  public var color: String = "white"
  
  public init() {}
  
  public init(from json: JSON) {
    bold = json.getBoolString(forKey: "bold") ?? bold
    italic = json.getBoolString(forKey: "bold") ?? italic
    underlined = json.getBoolString(forKey: "bold") ?? underlined
    strikethrough = json.getBoolString(forKey: "bold") ?? strikethrough
    obfuscated = json.getBoolString(forKey: "bold") ?? obfuscated
    color = json.getString(forKey: "color") ?? color
  }
}
