import Foundation
import simd

public struct EntityPosition {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public var chunkPosition: ChunkPosition {
    return ChunkPosition(
      chunkX: Int((x / 16).rounded(.down)),
      chunkZ: Int((z / 16).rounded(.down)))
  }
  
  public var vector: SIMD3<Float> {
    return SIMD3<Float>(
      Float(x),
      Float(y),
      Float(z))
  }
}
