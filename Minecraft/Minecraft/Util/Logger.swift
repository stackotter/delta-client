//
//  Logger.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 24/12/20.
//

import Foundation
import os

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
  }
  
  static func info(_ message: String, for object: Any? = nil) {
    if object != nil {
      Logger(for: object!).info("\(message)")
    }
    Logger().info("\(message)")
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
  }
}
