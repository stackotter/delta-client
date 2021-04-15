//
//  Camera.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/4/21.
//

import Foundation
import simd

struct Camera {
  var fovY: Float = 0.5 * .pi // 90deg
  var nearDistance: Float = 0.0001
  var farDistance: Float = 1000
  
  var aspect: Float = 1
  var position: simd_float3 = [0, 0, 0]
  
  var xRot: Float = 0
  var yRot: Float = 0
}
