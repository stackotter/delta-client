import Foundation
import simd

public struct EntityPosition {
  public var x: Double
  public var y: Double
  public var z: Double
  
  public var chunkPosition: ChunkPosition {
    let chunkX = Int((x / 16).rounded(.down))
    let chunkZ = Int((z / 16).rounded(.down))
    
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  public var vector: SIMD3<Float> {
    return SIMD3<Float>(
      Float(x),
      Float(y),
      Float(z)
    )
  }
}
