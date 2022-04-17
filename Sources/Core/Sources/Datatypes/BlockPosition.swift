import Foundation
import simd

/// A block position.
public struct BlockPosition {
  public var x: Int
  public var y: Int
  public var z: Int
  
  /// Create a new block position.
  ///
  /// Coordinates are not validated.
  ///
  /// - Parameters:
  ///   - x: The x coordinate.
  ///   - y: The y coordinate.
  ///   - z: The z coordinate.
  public init(x: Int, y: Int, z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }
  
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
  
  /// This position as a float vector
  public var floatVector: SIMD3<Float> {
    return SIMD3<Float>(
      Float(x),
      Float(y),
      Float(z))
  }
  
  /// This position as an int vector
  public var intVector: SIMD3<Int> {
    return SIMD3<Int>(x, y, z)
  }
  
  /// The positions neighbouring this position.
  public var neighbours: [BlockPosition] {
    Direction.allDirections.map { self + $0.intVector }
  }
  
  public static func + (lhs: BlockPosition, rhs: SIMD3<Int>) -> BlockPosition {
    return BlockPosition(x: lhs.x &+ Int(rhs.x), y: lhs.y &+ Int(rhs.y), z: lhs.z &+ Int(rhs.z))
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
}

extension BlockPosition: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
    hasher.combine(z)
  }
}
