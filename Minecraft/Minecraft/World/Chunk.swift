//
//  Chunk.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct Chunk {
  var chunkX: Int32
  var chunkZ: Int32
  
  var sections: [ChunkSection]
  var blockEntities: [BlockEntity]
  
  init(chunkX: Int32, chunkZ: Int32, sections: [ChunkSection], blockEntities: [BlockEntity], bitMask: Int32) {
    self.chunkX = chunkX
    self.chunkZ = chunkZ
    
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
