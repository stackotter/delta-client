//
//  Vertex.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

struct Vertex {
  var position: simd_float3 // using tuples instead of simd types because the stride is less
  var uv: simd_float2
  var light: Float
  var textureIndex: uint16
  var tintIndex: Int8
}
