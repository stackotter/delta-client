import FirebladeECS

/// A component storing an entity's hit box.
///
/// Entity hit boxes are axis aligned and their width and depth are always equal (``width``).
public class EntityHitBox: Component {
  /// The width (and depth) of the entity's hit box.
  public var width: Float
  /// The height of the entity's hit box.
  public var height: Float
  
  /// The size of the hit box as a vector.
  public var size: SIMD3<Float> {
    SIMD3(width, height, width)
  }
  
  /// Creates a new hit box component.
  public init(width: Float, height: Float) {
    self.width = width
    self.height = height
  }
}
