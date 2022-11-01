import FirebladeECS
import FirebladeMath

/// A component storing an entity's acceleration.
public class EntityAcceleration: Component {
  // MARK: Public properties

  /// The vector representing this acceleration.
  public var vector: Vec3d

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

  /// Creates an entity's acceleration.
  /// - Parameter vector: Vector representing the acceleration.
  public init(_ vector: Vec3d) {
    self.vector = vector
  }

  /// Creates an entity's acceleration.
  /// - Parameters:
  ///   - x: x component.
  ///   - y: y component.
  ///   - z: z component.
  public convenience init(_ x: Double, _ y: Double, _ z: Double) {
    self.init(Vec3d(x, y, z))
  }
}
