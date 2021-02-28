//
//  Position.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct Position {
  var x: Int32
  var y: Int32
  var z: Int32
  
  var chunkPosition: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  var relativeToChunk: Position {
    let relativeX = x - chunkPosition.chunkX*16
    let relativeZ = z - chunkPosition.chunkZ*16
    return Position(x: relativeX, y: y, z: relativeZ)
  }
}
