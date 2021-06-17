//
//  Camera.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/4/21.
//

import Foundation
import simd

/// Holds information about a camera to render from.
struct Camera {
  /// The vertical FOV.
  private(set) var fovY: Float = 0.5 * .pi // 90deg
  /// The near clipping plane.
  private(set) var nearDistance: Float = 0.01
  /// The far clipping plant.
  private(set) var farDistance: Float = 1000
  
  /// The aspect ratio.
  private(set) var aspect: Float = 1
  /// This camera's position.
  private(set) var position: simd_float3 = [0, 0, 0]
  
  /// This camera's rotation around the x axis (pitch).
  private(set) var xRot: Float = 0
  /// This camera's rotation aroudn the y axis (yaw).
  private(set) var yRot: Float = 0
  
  private(set) var frustum: Frustum?
  
  /// Sets this camera's vertical FOV. Horizontal FOV is calculated from vertical FOV and aspect ratio.
  mutating func setFovY(_ fovY: Float) {
    self.fovY = fovY
    recalculateFrustum()
  }
  
  /// Sets this camera's clipping planes.
  mutating func setClippingPlanes(near: Float, far: Float) {
    nearDistance = near
    farDistance = far
    recalculateFrustum()
  }
  
  /// Sets this camera's aspect ratio.
  mutating func setAspect(_ aspect: Float) {
    self.aspect = aspect
    recalculateFrustum()
  }
  
  /// Sets this camera's position in world coordinates.
  mutating func setPosition(_ position: simd_float3) {
    self.position = position
    recalculateFrustum()
  }
  
  /// Sets the rotation of this camera in radians.
  mutating func setRotation(xRot: Float, yRot: Float) {
    self.xRot = xRot
    self.yRot = yRot
    recalculateFrustum()
  }
  
  /// Invalidates the cached view frustum
  private mutating func recalculateFrustum() {
    frustum = calculateFrustum()
  }
  
  /// Calculates the camera's frustum from its parameters
  private func calculateFrustum() -> Frustum {
    let worldToClip = getWorldToClipMatrix()
    return Frustum(worldToClip: worldToClip)
  }
  
  /// Faces this camera in the direction described by a `PlayerRotation`.
  mutating func setRotation(playerLook: PlayerRotation) {
    xRot = playerLook.pitch / 180 * Float.pi
    yRot = playerLook.yaw / 180 * Float.pi
  }
  
  /// Returns this camera's world space to clip space transformation matrix.
  func getWorldToClipMatrix() -> matrix_float4x4 {
    var worldToCamera = MatrixUtil.translationMatrix(-position) // translation
    worldToCamera *= MatrixUtil.rotationMatrix(y: -(Float.pi + yRot)) // y rotation
    worldToCamera *= MatrixUtil.rotationMatrix(x: -xRot) // x rotation
    
    // perspective projection
    let cameraToClip = MatrixUtil.projectionMatrix(
      near: nearDistance,
      far: farDistance,
      aspect: aspect,
      fieldOfViewY: fovY)
    
    return worldToCamera * cameraToClip
  }
  
  /// Returns this camera's frustum. The frustum is cached until the camera's parameters are changed.
  func getFrustum() -> Frustum {
    if let frustum = frustum {
      return frustum
    } else {
      return calculateFrustum()
    }
  }
  
  /// Determine if the specified chunk is visible from this camera.
  func isChunkVisible(at chunkPosition: ChunkPosition) -> Bool {
    let chunkAxisAlignedBoundingBox = AxisAlignedBoundingBox(forChunkAt: chunkPosition)
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkAxisAlignedBoundingBox)
  }
  
  /// Determine if the specified chunk section is visible from this camera.
  func isChunkSectionVisible(at chunkSectionPosition: ChunkSectionPosition) -> Bool {
    let chunkSectionAxisAlignedBoundingBox = AxisAlignedBoundingBox(forChunkSectionAt: chunkSectionPosition)
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkSectionAxisAlignedBoundingBox)
  }
}
