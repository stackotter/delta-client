import FirebladeMath

public struct CelestialBodyUniforms {
  public var transformation: Mat4x4f
  public var textureIndex: UInt16
  public var uvPosition: Vec2f
  public var uvSize: Vec2f
  public var type: CelestialBodyType

  public enum CelestialBodyType: UInt8 {
    case sun = 0
    case moon = 1
  }
}
