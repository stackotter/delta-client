//
//  Uniforms.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation
import simd

struct Uniforms {
  var transformation: matrix_float4x4
  
  init(transformation: matrix_float4x4) {
    self.transformation = transformation
  }
  
  init() {
    transformation = matrix_float4x4(1)
  }
}
