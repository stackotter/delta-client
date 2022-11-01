import FirebladeECS
import FirebladeMath

/// A component storing an entity's hit box.
///
/// Entity hit boxes are axis aligned and their width and depth are always equal (``width``).
public class EntityHitBox: Component {
  /// The width (and depth) of the entity's hit box.
  public var width: Double
  /// The height of the entity's hit box.
  public var height: Double

  /// The size of the hit box as a vector.
  public var size: Vec3d {
    Vec3d(width, height, width)
  }

  /// Creates a new hit box component.
  public init(width: Double, height: Double) {
    self.width = width
    self.height = height
  }

  /// Creates a new hit box component.
  public init(width: Float, height: Float) {
    self.width = Double(width)
    self.height = Double(height)
  }

  /// The bounding box for this hitbox if it was at the given position.
  /// - Parameter position: The position of the hitbox.
  /// - Returns: A bounding box with the same size as the hitbox and the given position.
  public func aabb(at position: Vec3d) -> AxisAlignedBoundingBox {
    let position = position - 0.5 * Vec3d(size.x, 0, size.z)
    return AxisAlignedBoundingBox(position: position, size: size)
  }
}
