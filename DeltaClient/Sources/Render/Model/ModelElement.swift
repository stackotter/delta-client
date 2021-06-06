//
//  ModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation
import simd

struct ModelElement {
  var modelMatrix: matrix_float4x4
  var faces: [FaceDirection: ModelElementFace]
}
