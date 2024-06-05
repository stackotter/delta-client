/// The vertex format used by the entity shader.
public struct EntityVertex {
  public let x: Float
  public let y: Float
  public let z: Float
  public let r: Float
  public let g: Float
  public let b: Float
  public let u: Float
  public let v: Float
  /// ``UInt16/max`` indicates that no texture is to be used. I would usually use
  /// an optional to model that, but this type needs to be compatible with C as we
  /// pass it off to the shaders for rendering.
  public let textureIndex: UInt16

  public init(
    x: Float,
    y: Float,
    z: Float,
    r: Float,
    g: Float,
    b: Float,
    u: Float,
    v: Float,
    textureIndex: UInt16?
  ) {
    self.x = x
    self.y = y
    self.z = z
    self.r = r
    self.g = g
    self.b = b
    self.u = u
    self.v = v
    self.textureIndex = textureIndex ?? .max
  }
}
