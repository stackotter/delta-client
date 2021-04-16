//
//  IntermediateBlockModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import simd

struct IntermediateBlockModelElement {
  var modelMatrix: simd_float4x4
  var normalMatrix: simd_float3x3
  var faces: [FaceDirection: IntermediateBlockModelElementFace]
}
