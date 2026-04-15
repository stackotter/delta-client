/// The vertex format used by the entity shader.
public struct EntityVertex {
  public var x: Float
  public var y: Float
  public var z: Float
  public var r: Float
  public var g: Float
  public var b: Float
  public var u: Float
  public var v: Float
  public var skyLightLevel: UInt8
  public var blockLightLevel: UInt8
  /// ``UInt16/max`` indicates that no texture is to be used. I would usually use
  /// an optional to model that, but this type needs to be compatible with C as we
  /// pass it off to the shaders for rendering.
  public var textureIndex: UInt16

  public init(
    x: Float,
    y: Float,
    z: Float,
    r: Float,
    g: Float,
    b: Float,
    u: Float,
    v: Float,
    skyLightLevel: UInt8,
    blockLightLevel: UInt8,
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
    self.skyLightLevel = skyLightLevel
    self.blockLightLevel = blockLightLevel
    self.textureIndex = textureIndex ?? .max
  }
}
