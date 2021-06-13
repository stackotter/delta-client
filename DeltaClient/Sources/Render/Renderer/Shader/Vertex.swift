//
//  Vertex.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

struct Vertex {
  let position: simd_float3
  let uv: simd_float2
  let light: Float
  let textureIndex: uint16
  let tintIndex: Int8
  let skyLightLevel: UInt8
  let blockLightLevel: UInt8
}
