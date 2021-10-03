import Foundation
import simd

/// Holds information about a camera to render from.
public struct Camera {
  /// The vertical FOV.
  private(set) var fovY: Float = 0.5 * .pi // 90deg
  /// The near clipping plane.
  private(set) var nearDistance: Float = 0.01
  /// The far clipping plant.
  private(set) var farDistance: Float = 1000
  
  /// The aspect ratio.
  private(set) var aspect: Float = 1
  /// This camera's position.
  private(set) var position: SIMD3<Float> = [0, 0, 0]
  
  /// This camera's rotation around the x axis (pitch).
  private(set) var xRot: Float = 0
  /// This camera's rotation aroudn the y axis (yaw).
  private(set) var yRot: Float = 0
  
  private var frustum: Frustum?
  
  /// Sets this camera's vertical FOV. Horizontal FOV is calculated from vertical FOV and aspect ratio.
  public mutating func setFovY(_ fovY: Float) {
    self.fovY = fovY
    frustum = nil
  }
  
  /// Sets this camera's clipping planes.
  public mutating func setClippingPlanes(near: Float, far: Float) {
    nearDistance = near
    farDistance = far
    frustum = nil
  }
  
  /// Sets this camera's aspect ratio.
  public mutating func setAspect(_ aspect: Float) {
    self.aspect = aspect
    frustum = nil
  }
  
  /// Sets this camera's position in world coordinates.
  public mutating func setPosition(_ position: SIMD3<Float>) {
    self.position = position
    frustum = nil
  }
  
  /// Sets the rotation of this camera in radians.
  public mutating func setRotation(xRot: Float, yRot: Float) {
    self.xRot = xRot
    self.yRot = yRot
    frustum = nil
  }
  
  /// Calculates the camera's frustum from its parameters.
  public func calculateFrustum() -> Frustum {
    let worldToClip = getWorldToClipMatrix()
    return Frustum(worldToClip: worldToClip)
  }
  
  /// Faces this camera in the direction described by a `PlayerRotation`.
  public mutating func setRotation(playerLook: PlayerRotation) {
    xRot = playerLook.pitch / 180 * Float.pi
    yRot = playerLook.yaw / 180 * Float.pi
  }
  
  /// Returns this camera's world space to clip space transformation matrix.
  public func getWorldToClipMatrix() -> matrix_float4x4 {
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
  
  /// Calculates the camera's frustum and saves it. Cached frustum can be fetched via `getFrustum`.
  public mutating func cacheFrustum() {
    self.frustum = calculateFrustum()
  }
  
  public func getFrustum() -> Frustum {
    return frustum ?? calculateFrustum()
  }
  
  /// Determine if the specified chunk is visible from this camera.
  public func isChunkVisible(at chunkPosition: ChunkPosition) -> Bool {
    let chunkAxisAlignedBoundingBox = AxisAlignedBoundingBox(forChunkAt: chunkPosition)
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkAxisAlignedBoundingBox)
  }
  
  /// Determine if the specified chunk section is visible from this camera.
  public func isChunkSectionVisible(at chunkSectionPosition: ChunkSectionPosition) -> Bool {
    let chunkSectionAxisAlignedBoundingBox = AxisAlignedBoundingBox(forChunkSectionAt: chunkSectionPosition)
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkSectionAxisAlignedBoundingBox)
  }
}
