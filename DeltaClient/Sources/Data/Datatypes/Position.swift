//
//  Position.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import simd

struct Position: Hashable {
  var x: Int
  var y: Int
  var z: Int
  
  var chunkPosition: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  var relativeToChunk: Position {
    let relativeX = x - chunkPosition.chunkX * Chunk.Section.width
    let relativeZ = z - chunkPosition.chunkZ * Chunk.Section.depth
    return Position(x: relativeX, y: y, z: relativeZ)
  }
  
  var relativeToChunkSection: Position {
    let relativeX = x - chunkPosition.chunkX * Chunk.Section.width
    let relativeZ = z - chunkPosition.chunkZ * Chunk.Section.depth
    let relativeY = y - sectionIndex * Chunk.Section.height
    return Position(x: relativeX, y: relativeY, z: relativeZ)
  }
  
  var floatVector: simd_float3 {
    return simd_float3(
      Float(x),
      Float(y),
      Float(z))
  }
  
  var blockIndex: Int {
    return (y * Chunk.depth + z) * Chunk.width + x
  }
  
  var sectionIndex: Int {
    return y / Chunk.Section.height
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
    hasher.combine(z)
  }
}
