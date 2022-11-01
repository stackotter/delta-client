import Foundation
import FirebladeMath

/// A block position.
public struct BlockPosition {
  // MARK: Public properties

  /// The x component.
  public var x: Int
  /// The y component.
  public var y: Int
  /// The z component.
  public var z: Int

  /// The position of the ``Chunk`` this position is in
  public var chunk: ChunkPosition {
    let chunkX = x >> 4 // divides by 16 and rounds down
    let chunkZ = z >> 4
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }

  /// The position of the ``Chunk/Section`` this position is in
  public var chunkSection: ChunkSectionPosition {
    let sectionX = x >> 4 // divides by 16 and rounds down
    let sectionY = y >> 4
    let sectionZ = z >> 4
    return ChunkSectionPosition(sectionX: sectionX, sectionY: sectionY, sectionZ: sectionZ)
  }

  /// This position relative to the ``Chunk`` it's in
  public var relativeToChunk: BlockPosition {
    let relativeX = x &- chunk.chunkX &* Chunk.Section.width
    let relativeZ = z &- chunk.chunkZ &* Chunk.Section.depth
    return BlockPosition(x: relativeX, y: y, z: relativeZ)
  }

  /// This position relative to the ``Chunk/Section`` it's in
  public var relativeToChunkSection: BlockPosition {
    let relativeX = x &- chunk.chunkX &* Chunk.Section.width
    let relativeZ = z &- chunk.chunkZ &* Chunk.Section.depth
    let relativeY = y &- sectionIndex &* Chunk.Section.height
    return BlockPosition(x: relativeX, y: relativeY, z: relativeZ)
  }

  /// This position as a vector of floats.
  public var floatVector: Vec3f {
    return Vec3f(
      Float(x),
      Float(y),
      Float(z))
  }

  /// This position as a vector of doubles.
  public var doubleVector: Vec3d {
    return Vec3d(
      Double(x),
      Double(y),
      Double(z))
  }

  /// This position as a vector of ints.
  public var intVector: Vec3i {
    return Vec3i(x, y, z)
  }

  /// The positions neighbouring this position.
  public var neighbours: [BlockPosition] {
    Direction.allDirections.map { self + $0.intVector }
  }

  /// The block index of the position.
  ///
  /// Block indices are in order of increasing x-coordinate, in rows of increasing
  /// z-coordinate, in layers of increasing y. If that doesn't make sense read the
  /// implementation.
  public var blockIndex: Int {
    return (y &* Chunk.depth &+ z) &* Chunk.width &+ x
  }

  /// The biomes index of the position.
  ///
  /// Biome indices are in order of increasing x-coordinate, in rows of increasing
  /// z-coordinate, in layers of increasing y. If that doesn't make sense read the
  /// implementation. Each biome is a 4x4x4 area, and that's the only reason that
  /// this calculation differs from ``blockIndex``.
  public var biomeIndex: Int {
    return (y / 4 &* Chunk.depth / 4 &+ z / 4) &* Chunk.width / 4 &+ x / 4
  }

  /// The section Y of the section this position is in
  public var sectionIndex: Int {
    return y / Chunk.Section.height
  }

  // MARK: Init

  /// Create a new block position.
  ///
  /// Coordinates are not validated.
  /// - Parameters:
  ///   - x: The x coordinate.
  ///   - y: The y coordinate.
  ///   - z: The z coordinate.
  public init(x: Int, y: Int, z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }

  // MARK: Public methods

  /// Component-wise addition of two block positions.
  public static func + (lhs: BlockPosition, rhs: Vec3i) -> BlockPosition {
    return BlockPosition(x: lhs.x &+ rhs.x, y: lhs.y &+ rhs.y, z: lhs.z &+ rhs.z)
  }
}

extension BlockPosition: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
    hasher.combine(z)
  }
}
