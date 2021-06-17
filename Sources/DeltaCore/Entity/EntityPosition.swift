//
//  EntityPosition.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation
import simd

struct EntityPosition {
  var x: Double
  var y: Double
  var z: Double
  
  var chunkPosition: ChunkPosition {
    let chunkX = Int((x / 16).rounded(.down))
    let chunkZ = Int((z / 16).rounded(.down))
    
    return ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  var vector: simd_float3 {
    return simd_float3(
      Float(x),
      Float(y),
      Float(z)
    )
  }
}
