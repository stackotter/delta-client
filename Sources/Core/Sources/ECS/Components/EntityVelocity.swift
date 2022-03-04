import FirebladeECS

/// A component storing an entity's velocity in blocks per tick.
public class EntityVelocity: Component {
  // MARK: Public properties
  
  /// The vector representing this velocity.
  public var vector: SIMD3<Double>
  
  /// x component in blocks per tick.
  public var x: Double {
    get { vector.x }
    set { vector.x = newValue }
  }
  
  /// y component in blocks per tick.
  public var y: Double {
    get { vector.y }
    set { vector.y = newValue }
  }
  
  /// z component in blocks per tick.
  public var z: Double {
    get { vector.z }
    set { vector.z = newValue }
  }
  
  // MARK: Init
  
  /// Creates an entity's velocity.
  /// - Parameter vector: Vector representing the velocity.
  public init(_ vector: SIMD3<Double>) {
    self.vector = vector
  }
  
  /// Creates an entity's velocity.
  /// - Parameters:
  ///   - x: x component.
  ///   - y: y component.
  ///   - z: z component.
  public convenience init(_ x: Double, _ y: Double, _ z: Double) {
    self.init(SIMD3<Double>(x, y, z))
  }
}
