import Foundation

public enum JSONError: LocalizedError {
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
  case invalidSingleOrMultipleElement
}

public struct JSON {
  public var dict: [String: Any]
  
  public var keys: [String] {
    return [String](dict.keys)
  }
  
  public init(dict: [String: Any]) {
    self.dict = dict
  }
  
  public static func fromString(_ string: String) throws -> JSON {
    let data = string.data(using: .utf8)!
    guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw JSONError.failedToDeserialize
    }
    let json = JSON(dict: dict)
    return json
  }
  
  public func containsKey(_ key: String) -> Bool {
    return dict.keys.contains(key)
  }
  
  // Write
  
  public mutating func add(_ key: String, _ json: JSON) {
    dict[key] = json.dict
  }
  
  public mutating func addProperty(_ key: String, _ value: Any) {
    dict[key] = value
  }
  
  // Read
  
  public func getJSON(forKey key: String) -> JSON? {
    guard let value = dict[key] as? [String: Any] else {
      return nil
    }
    return JSON(dict: value)
  }
  
  public func getArray(forKey key: String) -> [Any]? {
    return dict[key] as? [Any]
  }
  
  public func getString(forKey key: String) -> String? {
    return dict[key] as? String
  }
  
  public func getInt(forKey key: String) -> Int? {
    return dict[key] as? Int
  }
  
  public func getFloat(forKey key: String) -> Double? {
    return dict[key] as? Double
  }
  
  public func getBoolString(forKey key: String) -> Bool? {
    let string = getString(forKey: key)
    return string == "true"
  }
  
  public func getBool(forKey key: String) -> Bool? {
    return dict[key] as? Bool
  }
  
  public func getAny(forKey key: String) -> Any? {
    return dict[key]
  }
}
