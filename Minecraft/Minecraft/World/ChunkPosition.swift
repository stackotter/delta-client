//
//  ChunkPosition.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkPosition: Hashable {
  // using chunkX and chunkZ instead of x and z to avoid confusion between coordinate systems later on
  // (chunkX is the coordinates of the chunk divided by 16 and rounded down)
  var chunkX: Int32
  var chunkZ: Int32
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(chunkX)
    hasher.combine(chunkZ)
  }
}
