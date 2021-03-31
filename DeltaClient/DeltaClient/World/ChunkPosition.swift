//
//  ChunkPosition.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkPosition: Hashable {
  var chunkX: Int
  var chunkZ: Int
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(chunkX)
    hasher.combine(chunkZ)
  }
}
