//
//  Chunk.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct Chunk {
  var position: ChunkPosition
  
  var sections: [ChunkSection]
  var blockEntities: [BlockEntity]
  
  init(position: ChunkPosition, sections: [ChunkSection], blockEntities: [BlockEntity], bitMask: Int32) {
    self.position = position
    
    self.sections = []
    var index = 0
    for i in 0..<16 {
      if bitMask >> i & 1 == 1 {
        self.sections.append(sections[index])
        index += 1
      } else {
        self.sections.append(ChunkSection())
      }
    }
    
    self.blockEntities = blockEntities
  }
}
