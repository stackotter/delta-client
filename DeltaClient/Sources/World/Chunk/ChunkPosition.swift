//
//  ChunkPosition.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

/// The position of a chunk.
struct ChunkPosition {
  /// The chunk's world x divided by 16 and rounded down.
  var chunkX: Int
  /// The chunk's world z divided by 16 and rounded down.
  var chunkZ: Int
  
  /// A map from each cardinal direction to each of this position's neighbours.
  var allNeighbours: [CardinalDirection: ChunkPosition] {
    return [
      .north: neighbour(inDirection: .north),
      .east: neighbour(inDirection: .east),
      .south: neighbour(inDirection: .south),
      .west: neighbour(inDirection: .west)]
  }
  
  /// An array of containing this position and its neighbours.
  var andNeighbours: [ChunkPosition] {
    var positionAndNeighbours = [self]
    positionAndNeighbours.append(contentsOf: allNeighbours.values)
    return positionAndNeighbours
  }
  
  /// Gets the position of the chunk that neighbours this chunk in the specified direction.
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
  
  /// Checks if a chunk position is a neighbour of this chunk position.
  func neighbours(_ potentialNeighbour: ChunkPosition) -> Bool {
    let manhattanDistance = abs(potentialNeighbour.chunkX - chunkX) + abs(potentialNeighbour.chunkZ - chunkZ)
    let isNeighbour = manhattanDistance == 1
    return isNeighbour
  }
  
  /// Checks if this chunk contains the specified chunk section.
  func contains(_ sectionPosition: ChunkSectionPosition) -> Bool {
    return sectionPosition.sectionX == chunkX && sectionPosition.sectionZ == chunkZ
  }
}

extension ChunkPosition: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(chunkX)
    hasher.combine(chunkZ)
  }
}
