import Foundation
import simd

/// An entity's position relative to the world.
public struct EntityPosition {
  public var x: Double
  public var y: Double
  public var z: Double
  
  /// Creates an entity's position.
  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }
  
  /// The chunk this position is in.
  public var chunkPosition: ChunkPosition {
    return ChunkPosition(
      chunkX: Int((x / 16).rounded(.down)),
      chunkZ: Int((z / 16).rounded(.down)))
  }
  
  /// The float vector representing this position.
  public var vector: SIMD3<Float> {
    return SIMD3<Float>(
      Float(x),
      Float(y),
      Float(z))
  }
}
