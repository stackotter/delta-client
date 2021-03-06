//
//  Vertex.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

struct Vertex {
  var position: vector_float3
  var modelToWorldTranslationIndex: uint32
  var textureCoordinate: vector_float2
}
