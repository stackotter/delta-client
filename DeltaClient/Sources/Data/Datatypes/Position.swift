//
//  Position.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import simd

struct Position {
  var x: Int
  var y: Int
  var z: Int
  
  /// The position of the `Chunk` this position is in
  var chunk: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  /// The position of the `Chunk.Section` this position is in
  var chunkSection: ChunkSectionPosition {
    let sectionX = x >> 4 // divides by 16 and rounds down
    let sectionY = y >> 4
    let sectionZ = z >> 4
    return ChunkSectionPosition(sectionX: sectionX, sectionY: sectionY, sectionZ: sectionZ)
  }
  
  /// This position relative to the `Chunk` it's in
  var relativeToChunk: Position {
    let relativeX = x - chunk.chunkX * Chunk.Section.width
    let relativeZ = z - chunk.chunkZ * Chunk.Section.depth
    return Position(x: relativeX, y: y, z: relativeZ)
  }
  
  /// This position relative to the `Chunk.Section` it's in
  var relativeToChunkSection: Position {
    let relativeX = x - chunk.chunkX * Chunk.Section.width
    let relativeZ = z - chunk.chunkZ * Chunk.Section.depth
    let relativeY = y - sectionIndex * Chunk.Section.height
    return Position(x: relativeX, y: relativeY, z: relativeZ)
  }
  
  /// This position as a float vector
  var floatVector: simd_float3 {
    return simd_float3(
      Float(x),
      Float(y),
      Float(z))
  }
  
  /**
   The block index of the position
   
   Blocks are placed in order of increasing x-coordinate, in rows of increasing
   z-coordinate, in layers of increasing y. If that doesn't make sense read the
   implementation.
   */
  var blockIndex: Int {
    return (y * Chunk.depth + z) * Chunk.width + x
  }
  
  /// The section Y of the section this position is in
  var sectionIndex: Int {
    return y / Chunk.Section.height
  }
}

extension Position: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
    hasher.combine(z)
  }
}
