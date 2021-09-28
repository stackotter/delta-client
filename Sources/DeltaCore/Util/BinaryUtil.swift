//
//  BinaryUtil.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/6/21.
//

import Foundation

/// A namespace for utility binary operations
enum BinaryUtil {
  /// Get a list of the indices of bits set in the first n bits of `bitmask`
  static func setBits(of bitmask: Int, n numberOfBits: Int) -> [Int] {
    let indices = (0..<numberOfBits).filter { index in
      return (bitmask >> index) & 0x1 == 0x1
    }
    return indices
  }
}
