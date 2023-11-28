import FirebladeMath

public struct CameraUniforms {
  /// Translation and rotation (sets up the camera's framing).
  public var framing: Mat4x4f
  /// The projection converting camera-space coordinates to clip-space coordinates.
  public var projection: Mat4x4f

  public init(framing: Mat4x4f, projection: Mat4x4f) {
    self.framing = framing
    self.projection = projection
  }
}
