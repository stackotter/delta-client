//
//  Position.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import simd

public struct Position {
  public var x: Int
  public var y: Int
  public var z: Int
  
  public init(x: Int, y: Int, z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }
  
  /// The position of the `Chunk` this position is in
  public var chunk: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  /// The position of the `Chunk.Section` this position is in
  public var chunkSection: ChunkSectionPosition {
    let sectionX = x >> 4 // divides by 16 and rounds down
    let sectionY = y >> 4
    let sectionZ = z >> 4
    return ChunkSectionPosition(sectionX: sectionX, sectionY: sectionY, sectionZ: sectionZ)
  }
  
  /// This position relative to the `Chunk` it's in
  public var relativeToChunk: Position {
    let relativeX = x &- chunk.chunkX &* Chunk.Section.width
    let relativeZ = z &- chunk.chunkZ &* Chunk.Section.depth
    return Position(x: relativeX, y: y, z: relativeZ)
  }
  
  /// This position relative to the `Chunk.Section` it's in
  public var relativeToChunkSection: Position {
    let relativeX = x &- chunk.chunkX &* Chunk.Section.width
    let relativeZ = z &- chunk.chunkZ &* Chunk.Section.depth
    let relativeY = y &- sectionIndex &* Chunk.Section.height
    return Position(x: relativeX, y: relativeY, z: relativeZ)
  }
  
  /// This position as a float vector
  public var floatVector: simd_float3 {
    return simd_float3(
      Float(x),
      Float(y),
      Float(z))
  }
  
  /// This position as an int vector
  public var intVector: simd_int3 {
    return simd_int3(
      Int32(x),
      Int32(y),
      Int32(z))
  }
  
  /// The positions neighbouring this position.
  public var neighbours: [Position] {
    Direction.allDirections.map { self + $0.intVector }
  }
  
  public static func + (lhs: Position, rhs: simd_int3) -> Position {
    return Position(x: lhs.x &+ Int(rhs.x), y: lhs.y &+ Int(rhs.y), z: lhs.z &+ Int(rhs.z))
  }
  
  /**
   The block index of the position
   
   Blocks are placed in order of increasing x-coordinate, in rows of increasing
   z-coordinate, in layers of increasing y. If that doesn't make sense read the
   implementation.
   */
  public var blockIndex: Int {
    return (y &* Chunk.depth &+ z) &* Chunk.width &+ x
  }
  
  /// The section Y of the section this position is in
  public var sectionIndex: Int {
    return y / Chunk.Section.height
  }
}

extension Position: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
    hasher.combine(z)
  }
}
