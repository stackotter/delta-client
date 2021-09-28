//
//  NBTTagType.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 27/6/21.
//

import Foundation

extension NBT {
  /// All possible NBT tag types
  public enum TagType: UInt8 {
    case end = 0
    case byte = 1
    case short = 2
    case int = 3
    case long = 4
    case float = 5
    case double = 6
    case byteArray = 7
    case string = 8
    case list = 9
    case compound = 10
    case intArray = 11
    case longArray = 12
  }
}
