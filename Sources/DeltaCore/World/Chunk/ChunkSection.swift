//
//  Section.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

extension Chunk {
  struct Section {
    static let width = Chunk.width
    static let height = Chunk.height / Chunk.numSections
    static let depth = Chunk.depth
    static let numBlocks = width * height * depth
    
    var blocks = [UInt16](repeating: 0, count: Section.numBlocks)
    var blockCount: Int16 = 0
    
    init() { } // used for empty chunks
    
    init(blockIds: [UInt16], palette: [UInt16], blockCount: Int16) {
      if !palette.isEmpty { // indirect palette
        self.blocks = blockIds.map {
          if $0 >= palette.count {
            log.warning("Indirect palette lookup failed: \($0) out of bounds for palette of length \(palette.count)")
            return 0
          }
          return palette[Int($0)]
        }
      } else {
        self.blocks = blockIds
      }
      self.blockCount = blockCount
    }
    
    func getBlockState(at position: Position) -> UInt16 {
      let index = position.blockIndex
      return getBlockState(at: index)
    }
    
    func getBlockState(at index: Int) -> UInt16 {
      assert(index < Section.numBlocks, "Invalid position passed to Chunk.Section.getBlockState(at:)")
      return blocks[index]
    }
    
    mutating func setBlockState(at position: Position, to newState: UInt16) {
      let index = position.blockIndex
      setBlockState(at: index, to: newState)
    }
    
    mutating func setBlockState(at index: Int, to newState: UInt16) {
      assert(index < Section.numBlocks, "Invalid position passed to Chunk.Section.setBlockState(at:to:)")
      self.blocks[index] = newState
      
      if getBlockState(at: index) == 0 {
        blockCount += 1
      }
      
      if newState == 0 {
        blockCount -= 1
      }
    }
  }
}
