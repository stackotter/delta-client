//
//  AxisAlignedBoundingBox.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/4/21.
//

import Foundation
import simd

struct AxisAlignedBoundingBox {
  var position: simd_float3
  var size: simd_float3
  
  func getVertices() -> [simd_float3] {
    let bfl = position
    let bfr = position + simd_float3(size.x, 0, 0)
    let tfl = position + simd_float3(0, size.y, 0)
    let tfr = position + simd_float3(size.x, size.y, 0)
    
    let bbl = position + simd_float3(0, 0, size.z)
    let bbr = position + simd_float3(size.x, 0, size.z)
    let tbl = position + simd_float3(0, size.y, size.z)
    let tbr = position + simd_float3(size.x, size.y, size.z)
    
    return [
      bfl,
      bfr,
      tfl,
      tfr,
      bbl,
      bbr,
      tbl,
      tbr
    ]
  }
}

extension AxisAlignedBoundingBox {
  init(forChunk chunk: Chunk) {
    self.init(forChunkAt: chunk.position)
  }
  
  init(forChunkAt chunkPosition: ChunkPosition) {
    self.position = [
      Float(chunkPosition.chunkX * Chunk.WIDTH),
      0.0,
      Float(chunkPosition.chunkZ * Chunk.DEPTH)
    ]
    self.size = [
      Float(Chunk.WIDTH),
      Float(Chunk.HEIGHT),
      Float(Chunk.DEPTH)
    ]
  }
}
