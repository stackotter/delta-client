//
//  BlockModelElementFace.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import simd

struct BlockModelElementFace {
  var uvs: [simd_float2]
  var textureIndex: UInt16 // the index of the texture to use in the block texture buffer
  var cullface: FaceDirection?
  var tintIndex: Int8
  var light: Float
}

extension BlockModelElementFace {
  init(fromCache cache: CacheBlockModelElementFace) {
    uvs = []
    for i in 0..<(cache.uvs.count / 2) {
      uvs.append(simd_float2(cache.uvs[i * 2], cache.uvs[i * 2 + 1]))
    }
    textureIndex = UInt16(cache.textureIndex)
    cullface = FaceDirection(fromCache: cache.cullFace)
    tintIndex = Int8(cache.tintIndex)
    light = cache.light
  }
  
  func toCache() -> CacheBlockModelElementFace {
    var cacheFace = CacheBlockModelElementFace()
    var uvFloats: [Float] = []
    for uv in uvs {
      uvFloats.append(uv.x)
      uvFloats.append(uv.y)
    }
    cacheFace.uvs = uvFloats
    cacheFace.textureIndex = UInt32(textureIndex)
    if let cacheCullface = cullface?.toCache() {
      cacheFace.cullFace = cacheCullface
    }
    cacheFace.tintIndex = Int32(tintIndex)
    cacheFace.light = light
    return cacheFace
  }
}
