//
//  CubeFaces.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation

struct CubeFaces: OptionSet {
  var rawValue: UInt8
  
  static let top = CubeFaces(rawValue: 0x1)
  static let bottom = CubeFaces(rawValue: 0x2)
  static let left = CubeFaces(rawValue: 0x4)
  static let right = CubeFaces(rawValue: 0x8)
  static let front = CubeFaces(rawValue: 0x10)
  static let back = CubeFaces(rawValue: 0x20)
}
