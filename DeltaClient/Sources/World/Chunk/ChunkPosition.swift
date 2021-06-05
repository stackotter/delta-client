//
//  ChunkPosition.swift
//  DeltaClient
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
  
  func neighbour(inDirection direction: CardinalDirection) -> ChunkPosition {
    var position = self
    switch direction {
      case .north:
        position.chunkZ -= 1
      case .east:
        position.chunkX += 1
      case .south:
        position.chunkZ += 1
      case .west:
        position.chunkX -= 1
    }
    return position
  }
}
