//
//  ModelElementFace.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation
import simd

struct ModelElementFace {
  var uvs: [simd_float2]
  var textureIndex: UInt16
  var cullface: FaceDirection?
  var tintIndex: Int8
  var lightLevel: LightLevel
}
