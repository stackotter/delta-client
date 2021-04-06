//
//  JSON.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 16/12/20.
//

import Foundation
import os

struct JSON {
  var dict: [String: Any]
  
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
  
  // Write
  
  mutating func add(_ key: String, _ json: JSON) {
    dict[key] = json.dict
  }
  
  mutating func addProperty(_ key: String, _ value: Any) {
    dict[key] = value
  }
  
  // Read
  
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
}
