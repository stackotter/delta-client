//
//  IntermediateBlockModelElementFace.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import simd

struct IntermediateBlockModelElementFace {
  var uv: (simd_float2, simd_float2)
  var textureVariable: String
  var cullface: FaceDirection?
  var rotation: Int
  var tintIndex: Int?
}
