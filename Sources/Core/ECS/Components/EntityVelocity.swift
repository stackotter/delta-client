/// An entity's velocity in blocks per tick.
public struct EntityVelocity {
  /// x velocity in blocks per tick.
  public var x: Double
  /// y velocity in blocks per tick.
  public var y: Double
  /// z velocity in blocks per tick.
  public var z: Double
  
  /// The vector representing this velocity.
  public var vector: SIMD3<Double> {
    return SIMD3<Double>(x, y, z)
  }
  
  /// Creates an entity's velocity.
  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }
  
  /// Creates an entity's velocity from a vector.
  public init(_ vector: SIMD3<Double>) {
    x = vector.x
    y = vector.y
    z = vector.z
  }
  
  /// Converts velocity measured in 1/8000ths of a block per tick, to blocks per tick.
  public init(x: Int16, y: Int16, z: Int16) {
    self.x = Double(x) / 8000
    self.y = Double(y) / 8000
    self.z = Double(z) / 8000
  }
}
