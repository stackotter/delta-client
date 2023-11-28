import FirebladeMath

public struct EntityUniforms {
  /// The transformation for an instance of the generic entity hitbox. Scales and
  /// translates the hitbox to the correct size and world-space position.
  public var transformation: Mat4x4f

  public init(transformation: Mat4x4f) {
    self.transformation = transformation
  }
}
