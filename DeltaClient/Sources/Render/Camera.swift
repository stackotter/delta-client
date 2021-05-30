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
  var nearDistance: Float = 0.01
  var farDistance: Float = 1000
  
  var aspect: Float = 1
  var position: simd_float3 = [0, 0, 0]
  
  var xRot: Float = 0
  var yRot: Float = 0
  
  mutating func setRotation(playerLook: PlayerRotation) {
    xRot = playerLook.pitch / 180 * Float.pi
    yRot = playerLook.yaw / 180 * Float.pi
  }
  
  func getWorldToClipMatrix() -> matrix_float4x4 {
    var worldToCamera = MatrixUtil.translationMatrix(-position) // translation
    worldToCamera *= MatrixUtil.rotationMatrix(y: -(Float.pi + yRot)) // y rotation
    worldToCamera *= MatrixUtil.rotationMatrix(x: -xRot) // x rotation
    
    // perspective projection
    let cameraToClip = MatrixUtil.projectionMatrix(near: nearDistance, far: farDistance, aspect: aspect, fieldOfViewY: fovY)
    
    return worldToCamera * cameraToClip
  }
  
  func getFrustum() -> Frustum {
    let worldToClip = getWorldToClipMatrix()
    return Frustum(worldToClip: worldToClip)
  }
}
