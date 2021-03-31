//
//  Identifier.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct Identifier: Equatable, Hashable, CustomStringConvertible {
  var namespace: String
  var name: String
  
  var description: String {
    return toString()
  }
  
  enum IdentifierError: LocalizedError {
    case invalidIdentifier
    case emptyString
  }
  
  init(_ string: String) throws {
    // a nice regex just for you
    let pattern = "^(([0-9a-z\\-_]+):)?([0-9a-z\\-_/\\.]+)$"
    let regex = try! NSRegularExpression(pattern: pattern)
    let result = regex.matches(in: string, range: NSMakeRange(0, string.utf8.count))
    if result.count == 0 {
      throw IdentifierError.emptyString
    }
    
    if let nameRange = Range(result[0].range(at: 3)) {
      if let namespaceRange = Range(result[0].range(at: 2)) {
        let start = String.Index(utf16Offset: namespaceRange.lowerBound, in: string)
        let end = String.Index(utf16Offset: namespaceRange.upperBound, in: string)
        namespace = String(string[start..<end])
      } else {
        namespace = "minecraft"
      }
      
      let start = String.Index(utf16Offset: nameRange.lowerBound, in: string)
      let end = String.Index(utf16Offset: nameRange.upperBound, in: string)
      name = String(string[start..<end])
    } else {
      throw IdentifierError.invalidIdentifier
    }
  }
  
  init(name: String) {
    self.init(namespace: "minecraft", name: name)
  }
  
  init(namespace: String, name: String) {
    self.namespace = namespace
    self.name = name
  }
  
  func toString() -> String {
    let string = "\(namespace):\(name)"
    return string
  }
  
  static func == (lhs: Identifier, rhs: Identifier) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.name == rhs.name
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(namespace)
    hasher.combine(name)
  }
}
