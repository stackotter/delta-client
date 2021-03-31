//
//  JSON.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 16/12/20.
//

import Foundation
import os

struct JSON {
  let dict: [String: Any]
  
  var keys: [String] {
    return [String](dict.keys)
  }
  
  enum JSONError: LocalizedError {
    case failedToOpenURL
    case failedToDeserialize
    case failedToGetJSON
    case failedToGetArray
    case failedToGetString
    case failedToGetInt
    case failedToGetFloat
    case failedToGetBool
    case failedToGetDouble
    case failedToGetAny
  }
  
  init() {
    self.dict = [:]
  }
  
  init(dict: [String: Any]) {
    self.dict = dict
  }
  
  static func fromURL(_ url: URL) throws -> JSON {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw JSONError.failedToOpenURL
    }
    
    return try fromData(data)
  }
  
  static func fromString(_ string: String) throws -> JSON {
    let data = string.data(using: .utf8)!
    return try fromData(data)
  }
  
  static func fromData(_ data: Data) throws -> JSON {
    guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw JSONError.failedToDeserialize
    }
    let json = JSON(dict: dict)
    return json
  }
  
  // returns true on success
  func writeTo(_ url: URL) -> Bool {
    do {
      let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
      try data.write(to: url)
      return true
    } catch {
      Logger.error("failed to write json to file `\(url.absoluteString)`")
      return false
    }
  }
  
  func containsKey(_ key: String) -> Bool {
    return dict.keys.contains(key)
  }
  
  // Optional return getters
  
  func getJSON(forKey key: String) -> JSON? {
    guard let value = dict[key] as? [String: Any] else {
      return nil
    }
    return JSON(dict: value)
  }
  
  func getArray(forKey key: String) -> [Any]? {
    return dict[key] as? [Any]
  }
  
  func getString(forKey key: String) -> String? {
    return dict[key] as? String
  }
  
  func getInt(forKey key: String) -> Int? {
    return dict[key] as? Int
  }
  
  func getFloat(forKey key: String) -> Double? {
    return dict[key] as? Double
  }
  
  func getBoolString(forKey key: String) -> Bool? {
    let string = getString(forKey: key)
    return string == "true"
  }
  
  func getBool(forKey key: String) -> Bool? {
    return dict[key] as? Bool
  }
  
  func getAny(forKey key: String) -> Any? {
    return dict[key]
  }
  
  // Throwing getters
  
  func getJSONThrowing(forKey key: String) throws -> JSON {
    guard let value = dict[key] as? [String: Any] else {
      throw JSONError.failedToGetJSON
    }
    return JSON(dict: value)
  }
  
  func getArrayThrowing(forKey key: String) throws -> [Any] {
    guard let array = dict[key] as? [Any] else {
      throw JSONError.failedToGetArray
    }
    return array
  }
  
  func getStringThrowing(forKey key: String) throws -> String {
    guard let string = dict[key] as? String else {
      throw JSONError.failedToGetString
    }
    return string
  }
  
  func getIntThrowing(forKey key: String) throws -> Int {
    guard let int = dict[key] as? Int else {
      throw JSONError.failedToGetInt
    }
    return int
  }
  
  func getFloatThrowing(forKey key: String) throws -> Double {
    guard let float = dict[key] as? Double else {
      throw JSONError.failedToGetFloat
    }
    return float
  }
  
  func getBoolThrowing(forKey key: String) throws -> Bool {
    guard let string = getString(forKey: key) else {
      throw JSONError.failedToGetBool
    }
    return string == "true"
  }
  
  func getAnyThrowing(forKey key: String) throws -> Any {
    guard let any = dict[key] else {
      throw JSONError.failedToGetAny
    }
    return any
  }
}
