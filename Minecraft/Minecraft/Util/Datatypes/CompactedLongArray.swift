//
//  CompactedLongArray.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

// NOTE: this format of compacted long array is new in 1.16.1, entries no longer get split across two longs
struct CompactedLongArray {
  var bitsPerEntry: Int
  var longArray: [Int64] = []
  var numEntries: Int
  
  init(_ longArray: [Int64], bitsPerEntry: Int, numEntries: Int) {
    self.longArray = longArray
    self.bitsPerEntry = bitsPerEntry
    self.numEntries = numEntries
  }
  
  func decompact() -> [Int32] {
    // could limiting to Int32 be a problem anywhere? surely compacted long arrays wouldn't have entries longer than 32 bits
    var output: [Int32] = []
    let nPerLong = Int((64/Float(bitsPerEntry)).rounded(.down))
    let mask: Int64 = (1 << bitsPerEntry) - 1
    for long in longArray {
      for i in 0..<nPerLong {
        let int = Int32(Int64(long >> (bitsPerEntry * i)) & mask)
        output.append(int)
      }
    }
    output = Array(output[0..<numEntries])
    return output
  }
}
