//
//  JSON.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 16/12/20.
//

import Foundation

struct JSON {
  let dict: [String: Any]
  
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
  
  func getJSON(forKey key: String) throws -> JSON {
    guard let value = dict[key] as? [String: Any] else {
      throw JSONError.failedToGetJSON
    }
    return JSON(dict: value)
  }
  
  func getString(forKey key: String) throws -> String {
    guard let string = dict[key] as? String else {
      throw JSONError.failedToGetString
    }
    return string
  }
  
  func getInt(forKey key: String) throws -> Int {
    guard let int = dict[key] as? Int else {
      throw JSONError.failedToGetInt
    }
    return int
  }
  
  func getFloat(forKey key: String) throws -> Double {
    guard let double = dict[key] as? Double else {
      throw JSONError.failedToGetDouble
    }
    return double
  }
}
