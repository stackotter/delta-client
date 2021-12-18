import Foundation

/// The position of a chunk section.
public struct ChunkSectionPosition {
  /// The world x of the section divided by 16 and rounded down.
  public var sectionX: Int
  /// The world y of the section divided by 16 and rounded down.
  public var sectionY: Int
  /// The world z of the section divided by 16 and rounded down.
  public var sectionZ: Int
  
  /// The position of the chunk this section is in.
  public var chunk: ChunkPosition {
    return ChunkPosition(chunkX: sectionX, chunkZ: sectionZ)
  }
  
  /// The axis aligned bounding box for this chunk section.
  public var axisAlignedBoundingBox: AxisAlignedBoundingBox {
    AxisAlignedBoundingBox(
      position: [
        Float(sectionX * Chunk.Section.width),
        Float(sectionY * Chunk.Section.height),
        Float(sectionZ * Chunk.Section.depth)
      ],
      size: [
        Float(Chunk.Section.width),
        Float(Chunk.Section.height),
        Float(Chunk.Section.depth)
      ])
  }
  
  /// Checks that the section's Y value is valid.
  public var isValid: Bool {
    return sectionY >= 0 && sectionY < Chunk.numSections
  }
  
  /// Create a new chunk section position.
  public init(sectionX: Int, sectionY: Int, sectionZ: Int) {
    self.sectionX = sectionX
    self.sectionY = sectionY
    self.sectionZ = sectionZ
  }
  
  /// Create a new `ChunkSectionPosition` in the chunk at `chunkPosition` located at `sectionY`.
  ///
  /// `sectionY` is not the world Y of the `Chunk.Section`. It is the world Y divided
  /// by 16 and rounded down. This means it should be from 0 to 15.
  ///
  /// - Parameter chunkPosition: The position of the chunk this section is in
  /// - Parameter sectionY: The section Y of the section (from 0 to 15 inclusive).
  public init(_ chunkPosition: ChunkPosition, sectionY: Int) {
    sectionX = chunkPosition.chunkX
    self.sectionY = sectionY
    sectionZ = chunkPosition.chunkZ
  }
  
  /// Gets the position of the section that neighbours this section in the specified direction.
  /// - Parameter direction: Direction to find neighbour in.
  /// - Returns: The position of the neighbour.
  public func neighbour(inDirection direction: Direction) -> ChunkSectionPosition {
    var position = self
    switch direction {
      case .north:
        position.sectionZ -= 1
      case .east:
        position.sectionX += 1
      case .south:
        position.sectionZ += 1
      case .west:
        position.sectionX -= 1
      case .up:
        position.sectionY += 1
      case .down:
        position.sectionY -= 1
    }
    
    return position
  }
  
  /// Gets the position of the section that neighbours this section in the specified direction if it's valid.
  ///
  /// Returns `nil` if the neighbour position isn't valid (see ``isValid``).
  /// - Parameter direction: Direction to find neighbour in.
  /// - Returns: The position of the neighbour unless the neighbour is above or below the world.
  public func validNeighbour(inDirection direction: Direction) -> ChunkSectionPosition? {
    let position = neighbour(inDirection: direction)
    if position.isValid {
      return position
    } else {
      return nil
    }
  }
}

extension ChunkSectionPosition: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sectionX)
    hasher.combine(sectionY)
    hasher.combine(sectionZ)
  }
}

extension ChunkSectionPosition: Equatable {
  public static func ==(_ lhs: ChunkSectionPosition, _ rhs: ChunkSectionPosition) -> Bool {
    return lhs.sectionX == rhs.sectionX && lhs.sectionZ == rhs.sectionZ && lhs.sectionY == rhs.sectionY
  }
}
