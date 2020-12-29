//
//  UUID.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 29/12/20.
//

import Foundation

// adding a convenience method to more consistently get a UUID from a string (cause minecraft randomly gives you ones without hyphens)
extension UUID {
  static func fromString(_ string: String) -> UUID? {
    let cleanedString: String
    var matches = string.range(of: "^[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$", options: .regularExpression)
    if matches != nil {
      cleanedString = string
    } else {
      matches = string.range(of: "^[a-fA-F0-9]{32}", options: .regularExpression)
      if matches != nil {
        let tempString: NSMutableString = NSMutableString(string: string)
        tempString.insert("-", at: 20)
        tempString.insert("-", at: 16)
        tempString.insert("-", at: 12)
        tempString.insert("-", at: 8)
        cleanedString = tempString as String
      } else {
        return nil
      }
    }
    
    return UUID(uuidString: cleanedString)
  }
  
  func toBytes() -> [UInt8] {
    let (u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16) = self.uuid
    return [u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16]
  }
}
