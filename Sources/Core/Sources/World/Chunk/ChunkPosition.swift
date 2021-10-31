import Foundation

/// The position of a chunk.
public struct ChunkPosition {
  /// The chunk's world x divided by 16 and rounded down.
  public var chunkX: Int
  /// The chunk's world z divided by 16 and rounded down.
  public var chunkZ: Int
  
  public init(chunkX: Int, chunkZ: Int) {
    self.chunkX = chunkX
    self.chunkZ = chunkZ
  }
  
  /// A map from each cardinal direction to each of this position's neighbours.
  public var allNeighbours: [CardinalDirection: ChunkPosition] {
    return [
      .north: neighbour(inDirection: .north),
      .east: neighbour(inDirection: .east),
      .south: neighbour(inDirection: .south),
      .west: neighbour(inDirection: .west)]
  }
  
  /// An array of containing this position and its neighbours.
  public var andNeighbours: [ChunkPosition] {
    var positionAndNeighbours = [self]
    positionAndNeighbours.append(contentsOf: allNeighbours.values)
    return positionAndNeighbours
  }
  
  /// The axis aligned bounding box for this chunk.
  public var axisAlignedBoundingBox: AxisAlignedBoundingBox {
    AxisAlignedBoundingBox(
      position: [
        Float(chunkX * Chunk.width),
        0.0,
        Float(chunkZ * Chunk.depth)
      ],
      size: [
        Float(Chunk.width),
        Float(Chunk.height),
        Float(Chunk.depth)
      ])
  }
  
  /// Gets the position of the chunk that neighbours this chunk in the specified direction.
  public func neighbour(inDirection direction: CardinalDirection) -> ChunkPosition {
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
  public func neighbours(_ potentialNeighbour: ChunkPosition) -> Bool {
    let manhattanDistance = abs(potentialNeighbour.chunkX - chunkX) + abs(potentialNeighbour.chunkZ - chunkZ)
    let isNeighbour = manhattanDistance == 1
    return isNeighbour
  }
  
  /// Checks if this chunk contains the specified chunk section.
  public func contains(_ sectionPosition: ChunkSectionPosition) -> Bool {
    return sectionPosition.sectionX == chunkX && sectionPosition.sectionZ == chunkZ
  }
}

extension ChunkPosition: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(chunkX)
    hasher.combine(chunkZ)
  }
}
