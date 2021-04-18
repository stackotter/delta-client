//
//  ChunkSection.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

struct ChunkSection {
  static let WIDTH = Chunk.WIDTH
  static let HEIGHT = Chunk.HEIGHT / Chunk.NUM_SECTIONS
  static let DEPTH = Chunk.DEPTH
  static let NUM_BLOCKS = WIDTH * HEIGHT * DEPTH
  
  var blocks: [UInt16]
  var blockCount: Int16
  
  init() { // used for empty chunks
    blocks = [UInt16](repeating: 0, count: ChunkSection.NUM_BLOCKS)
    blockCount = 0
  }
  
  init(blockIds: [UInt16], palette: [UInt16], blockCount: Int16) {
    self.blocks = blockIds
    if !palette.isEmpty { // indirect palette
      self.blocks = self.blocks.map {
        if $0 >= palette.count {
          Logger.warning("indirect palette lookup failed: \($0) out of bounds for palette of length \(palette.count)")
          return 0
        }
        return palette[Int($0)]
      }
    }
    self.blockCount = blockCount
  }
  
  func blockIndexFrom(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return (y * ChunkSection.DEPTH + z) * ChunkSection.WIDTH + x
  }
  
  func getBlockId(atX x: Int, y: Int, andZ z: Int) -> UInt16 {
    let index = blockIndexFrom(x, y, z)
    let blockId = blocks[index]
    return blockId
  }
  
  mutating func setBlockId(atX x: Int, y: Int, andZ z: Int, to state: UInt16) {
    if getBlockId(atX: x, y: y, andZ: z) == 0 {
      blockCount += 1
    }
    if state == 0 {
      blockCount -= 1
    }
    let index = blockIndexFrom(x, y, z)
    self.blocks[index] = state
  }
}
