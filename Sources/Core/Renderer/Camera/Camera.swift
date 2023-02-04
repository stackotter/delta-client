import Foundation
import Metal
import FirebladeMath
import DeltaCore

/// Holds information about a camera to render from.
public struct Camera {
  // MARK: Public properties

  /// The vertical FOV in radians.
  public private(set) var fovY: Float = 0.5 * .pi // 90deg
  /// The near clipping plane.
  public private(set) var nearDistance: Float = 0.04
  /// The far clipping plant.
  public private(set) var farDistance: Float = 800

  /// The aspect ratio.
  public private(set) var aspect: Float = 1
  /// The camera's position.
  public private(set) var position: Vec3f = [0, 0, 0]

  /// The camera's rotation around the x axis (pitch). -pi/2 radians is straight up, 0 is straight ahead, and pi/2 radians is straight up.
  public private(set) var xRot: Float = 0
  /// The camera's rotation around the y axis measured counter-clockwise from the positive z axis when looking down from above (yaw).
  public private(set) var yRot: Float = 0

  // MARK: Public computed properties

  /// The camera's position as an entity position.
  public var entityPosition: EntityPosition {
    return EntityPosition(Vec3d(position))
  }

  /// The direction that the camera is pointing.
  public var directionVector: Vec3f {
    let rotationMatrix = MatrixUtil.rotationMatrix(y: Float.pi + yRot) * MatrixUtil.rotationMatrix(x: xRot)
    let unitVector = Vec4f(0, 0, 1, 0)
    return (unitVector * rotationMatrix).xyz
  }

  // MARK: Private properties

  private var frustum: Frustum?

  private var uniformsBuffers: [MTLBuffer] = []
  private var uniformsIndex = 0
  private var uniformsCount = 6

  // MARK: Init

  public init(_ device: MTLDevice) throws {
    for i in 0..<uniformsCount {
      guard let buffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared) else {
        throw RenderError.failedtoCreateWorldUniformBuffers
      }
      buffer.label = "dev.stackotter.Camera.uniforms-\(i)"
      uniformsBuffers.append(buffer)
    }
  }

  // MARK: Public methods

  /// Update a buffer to contain the current world to clip uniforms.
  public mutating func getUniformsBuffer() -> MTLBuffer {
    let buffer = uniformsBuffers[uniformsIndex]
    uniformsIndex = (uniformsIndex + 1) % uniformsCount
    var uniforms = getUniforms()
    buffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
    return buffer
  }

  /// Get the world to clip uniforms.
  public mutating func getUniforms() -> Uniforms {
    let transformation = getFrustum().worldToClip
    return Uniforms(transformation: transformation)
  }

  /// Sets this camera's vertical FOV. Horizontal FOV is calculated from vertical FOV and aspect ratio.
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
  public mutating func setPosition(_ position: Vec3f) {
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

  /// Faces this camera in the direction of an entity's rotation.
  public mutating func setRotation(playerLook: EntityRotation) {
    xRot = playerLook.pitch
    yRot = playerLook.yaw
  }

  /// Returns this camera's world space to clip space transformation matrix.
  public func getWorldToClipMatrix() -> Mat4x4f {
    var worldToCamera = MatrixUtil.translationMatrix(-position) // translation
    worldToCamera *= MatrixUtil.rotationMatrix(y: -(Float.pi + yRot)) // y rotation
    worldToCamera *= MatrixUtil.rotationMatrix(x: -xRot) // x rotation

    // perspective projection
    let cameraToClip = MatrixUtil.projectionMatrix(
      near: nearDistance,
      far: farDistance,
      aspect: aspect,
      fieldOfViewY: fovY
    )

    return worldToCamera * cameraToClip
  }

  /// Calculates the camera's frustum and saves it. Cached frustum can be fetched via ``getFrustum()``.
  public mutating func cacheFrustum() {
    self.frustum = calculateFrustum()
  }

  public func getFrustum() -> Frustum {
    return frustum ?? calculateFrustum()
  }

  /// Determine if the specified chunk is visible from this camera.
  public func isChunkVisible(at chunkPosition: ChunkPosition) -> Bool {
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkPosition.axisAlignedBoundingBox)
  }

  /// Determine if the specified chunk section is visible from this camera.
  public func isChunkSectionVisible(at chunkSectionPosition: ChunkSectionPosition) -> Bool {
    let frustum = getFrustum()
    return frustum.approximatelyContains(chunkSectionPosition.axisAlignedBoundingBox)
  }
}
