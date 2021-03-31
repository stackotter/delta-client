//
//  Logger.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/12/20.
//

import Foundation
import os

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
  }
  
  mutating func addColoured(_ str: String, _ styles: [Style]) {
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

extension Logger {
  init(for object: Any, desc: String? = nil) {
    let subsystem = Bundle.main.bundleIdentifier!
    let category = String(describing: object)
    self.init(subsystem: subsystem, category: desc == nil ? category : "\(category) \(desc!)")
  }
  
  static func debug(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).debug("\(message)")
    }
    Logger().debug("\(message)")
  }
  
  static func log(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).log("\(message)")
    }
    Logger().log("\(message)")
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.add("[ LOG ]  ")
    logMessage.add(message)
    print(logMessage.toString())
    #endif
  }
  
  static func info(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).info("\(message)")
    }
    Logger().info("\(message)")
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.add("[ INFO ] ")
    logMessage.add(message)
    print(logMessage.toString())
    #endif
  }
  
  static func critical(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).critical("\(message)")
    }
    Logger().critical("\(message)")
  }
  
  static func warning(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).warning("\(message)")
    }
    Logger().warning("\(message)")
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.addColoured("[ WARN ] ", [.yellow, .bold])
    logMessage.add(message)
    print(logMessage.toString())
    #endif
  }
  
  static func notice(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).notice("\(message)")
    }
    Logger().notice("\(message)")
  }
  
  static func fault(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).fault("\(message)")
    }
    Logger().fault("\(message)")
  }
  
  static func trace(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).trace("\(message)")
    }
    Logger().trace("\(message)")
  }
  
  static func error(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).error("\(message)")
    }
    Logger().error("\(message)")
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.addColoured("[ ERR ]  ", [.red, .bold])
    logMessage.add(message)
    print(logMessage.toString())
    #endif
  }
}
