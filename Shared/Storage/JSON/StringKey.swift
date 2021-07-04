//
//  StringKey.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// A dynamic coding key for decoding dictionaries with custom keys.
struct StringKey: CodingKey {
  let stringValue: String
  let intValue: Int?
  
  init?(stringValue: String) {
    self.intValue = nil
    self.stringValue = stringValue
  }
  
  init?(intValue: Int) {
    self.intValue = intValue
    self.stringValue = "\(intValue)"
  }
}
