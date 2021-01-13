//
//  ChunkSection.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkSection {
  var blocks: [Int32] = []
  
  var isEmpty: Bool {
    return blocks.count == 0
  }
  
  init() {
    
  }
  
  init(blockIds: [Int32]) {
    self.blocks = blockIds
  }
}
