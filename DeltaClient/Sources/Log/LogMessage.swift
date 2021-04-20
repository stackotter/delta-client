//
//  LogMessage.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/4/21.
//

import Foundation

struct LogMessage {
  var string = ""
  
  enum Style: Int {
    case bold = 1
    
    case black = 30
    case red = 31
    case green = 32
    case yellow = 33
    case blue = 34
    case magenta = 35
    case cyan = 36
    case white = 37
    
    static let trace: [Style] = []
    static let debug: [Style] = []
    static let info: [Style] = []
    static let warn: [Style] = [.yellow, .bold]
    static let error: [Style] = [.red, .bold]
  }
  
  mutating func add(_ str: String, _ styles: [Style]) {
    setStyles(styles)
    add(str)
    setStyles([])
  }
  
  mutating func add(_ str: String) {
    string += str
  }
  
  mutating func setStyles(_ styles: [Style]) {
    let codes = styles.map {
      return "\($0.rawValue)"
    }
    let code = "\u{001B}[0;\(codes.joined(separator: ";"))m"
    string += code
  }
  
  func toString() -> String {
    return string
  }
}
