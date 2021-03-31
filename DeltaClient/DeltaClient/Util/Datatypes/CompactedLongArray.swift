//
//  CompactedLongArray.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

// NOTE: this format of compacted long array is new in 1.16.1, entries no longer get split across two longs
struct CompactedLongArray {
  var bitsPerEntry: UInt64
  var longArray: [UInt64] = []
  var numEntries: Int
  
  init(_ longArray: [UInt64], bitsPerEntry: UInt64, numEntries: Int) {
    self.longArray = longArray
    self.bitsPerEntry = bitsPerEntry
    self.numEntries = numEntries
  }
  
  func decompact() -> [UInt64] {
    let nPerLong = Int((64/Float(bitsPerEntry)).rounded(.down))
    var output: [UInt64] = [UInt64](repeating: 0, count: numEntries + nPerLong)
    let mask: UInt64 = (1 << bitsPerEntry) - 1

    let offsets: [UInt64] = (0..<nPerLong).map { // a look up table to cut out repeated calculations in loop (cuts 1ms off what used to take 7ms)
      return bitsPerEntry * UInt64($0)
    }
    var entryNum = 0
    
    for long in longArray {
      for i in 0..<nPerLong {
        let int = long >> offsets[i] & mask
        output[entryNum] = int
        entryNum += 1
      }
    }

    output = Array(output[0..<numEntries])
    return output
  }
}
