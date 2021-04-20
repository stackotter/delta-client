//
//  Logger.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 24/12/20.
//

import Foundation
import os

struct Logger {
  static let shared = Logger()
  
  private var osLogger: os.Logger
  
  init() {
    osLogger = os.Logger()
  }
  
  init(name: String, detail: String = "") {
    osLogger = os.Logger(subsystem: name, category: detail)
  }
  
  func trace(_ message: String) {
    osLogger.debug("\(message)")
  }
  
  func debug(_ message: String) {
    osLogger.debug("\(message)")
  }
  
  func info(_ message: String) {
    osLogger.info("\(message)")
    
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.add("[ INFO ] ", [.bold])
    logMessage.add(message, LogMessage.Style.info)
    print(logMessage.toString())
    #endif
  }
  
  func warn(_ message: String) {
    osLogger.warning("\(message)")
    
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.add("[ WARN ] ", [.bold])
    logMessage.add(message, LogMessage.Style.warn)
    print(logMessage.toString())
    #endif
  }
  
  func error(_ message: String) {
    osLogger.error("\(message)")
    
    #if !DEBUG
    var logMessage = LogMessage()
    logMessage.add("[ ERR ]  ", [.bold])
    logMessage.add(message, LogMessage.Style.error)
    print(logMessage.toString())
    #endif
  }
}

extension Logger {
  static func trace(_ message: String) {
    Logger.shared.trace(message)
  }
  
  static func debug(_ message: String) {
    Logger.shared.debug(message)
  }
  
  static func info(_ message: String) {
    Logger.shared.info(message)
  }
  
  static func warn(_ message: String) {
    Logger.shared.warn(message)
  }
  
  static func error(_ message: String) {
    Logger.shared.error(message)
  }
}
