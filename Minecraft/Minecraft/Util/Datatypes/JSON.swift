//
//  JSON.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 16/12/20.
//

import Foundation

struct JSON {
  let dict: [String: Any]
  
  var keys: [String] {
    return [String](dict.keys)
  }
  
  enum JSONError: LocalizedError {
    case failedToOpenURL
    case failedToDeserialize
    case failedToGetJSON
    case failedToGetString
    case failedToGetInt
    case failedToGetDouble
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
  
  func containsKey(_ key: String) -> Bool {
    return dict.keys.contains(key)
  }
  
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
  
  func getBool(forKey key: String) -> Bool? {
    let string = getString(forKey: key)
    return string == "true"
  }
  
  func getAny(forKey key: String) -> Any? {
    return dict[key]
  }
}
