//
//  Position.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct Position {
  var x: Int
  var y: Int
  var z: Int
  
  var chunkPosition: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  var relativeToChunk: Position {
    let relativeX = x - chunkPosition.chunkX * ChunkSection.WIDTH
    let relativeZ = z - chunkPosition.chunkZ * ChunkSection.DEPTH
    return Position(x: relativeX, y: y, z: relativeZ)
  }
  
  var relativeToChunkSection: Position {
    let relativeX = x - chunkPosition.chunkX * ChunkSection.WIDTH
    let relativeZ = z - chunkPosition.chunkZ * ChunkSection.DEPTH
    let relativeY = y - sectionIndex * ChunkSection.HEIGHT
    return Position(x: relativeX, y: relativeY, z: relativeZ)
  }
  
  var index: Int {
    return (y * Chunk.DEPTH + z) * Chunk.WIDTH + x
  }
  
  var sectionIndex: Int {
    return y / ChunkSection.HEIGHT
  }
}
