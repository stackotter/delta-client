//
//  EntityPosition.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/1/21.
//

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
  
  public var vector: simd_float3 {
    return simd_float3(
      Float(x),
      Float(y),
      Float(z)
    )
  }
}
