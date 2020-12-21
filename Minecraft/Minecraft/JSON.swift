//
//  JSON.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 16/12/20.
//

import Foundation

// TODO: error handling
struct JSON {
  let dict: [String: Any]
  
  static func fromURL(_ url: URL) -> JSON {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      fatalError("couldn't open url to read nbt data")
    }
    
    return fromData(data)
  }
  
  static func fromString(_ string: String) -> JSON {
    let data = string.data(using: .utf8)!
    return fromData(data)
  }
  
  static func fromData(_ data: Data) -> JSON {
    let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    let json = JSON(dict: dict!)
    return json
  }
  
  func getJSON(forKey key: String) -> JSON {
    let value = dict[key] as! [String: Any]
    return JSON(dict: value)
  }
  
  func getString(forKey key: String) -> String {
    let string = dict[key] as! String
    return string
  }
  
  func getInt(forKey key: String) -> Int {
    let int = dict[key] as! Int
    return int
  }
  
  func getFloat(forKey key: String) -> Double {
    let double = dict[key] as! Double
    return double
  }
}
