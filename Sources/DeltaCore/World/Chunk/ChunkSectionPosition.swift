//
//  ChunkSectionPosition.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 10/6/21.
//

import Foundation

/// The position of a chunk section
public struct ChunkSectionPosition {
  /// The world x of the section divided by 16 and rounded down
  public var sectionX: Int
  /// The world y of the section divided by 16 and rounded down
  public var sectionY: Int
  /// The world z of the section divided by 16 and rounded down
  public var sectionZ: Int
  
  /// The position of the chunk this section is in
  public var chunk: ChunkPosition {
    return ChunkPosition(chunkX: sectionX, chunkZ: sectionZ)
  }
  
  public init(sectionX: Int, sectionY: Int, sectionZ: Int) {
    self.sectionX = sectionX
    self.sectionY = sectionY
    self.sectionZ = sectionZ
  }
}

extension ChunkSectionPosition {
  /**
   Creates a new `ChunkSectionPosition` in chunk at `chunkPosition` located at `sectionY`
   
   `sectionY` is not the world Y of the `Chunk.Section`. It is the world Y divided
   by 16 and rounded down. This means it should be from 0 to 15.
   
   - Parameter chunkPosition: The position of the chunk this section is in
   - Parameter sectionY: The section Y of the section (from 0 to 15 inclusive).
   */
  public init(_ chunkPosition: ChunkPosition, sectionY: Int) {
    sectionX = chunkPosition.chunkX
    self.sectionY = sectionY
    sectionZ = chunkPosition.chunkZ
  }
}

extension ChunkSectionPosition: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sectionX)
    hasher.combine(sectionY)
    hasher.combine(sectionZ)
  }
}
