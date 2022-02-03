import FirebladeECS

/// A component storing the yaw of an entity's head.
public class EntityHeadYaw: Component {
  /// The yaw of an entity's head (counter clockwise starting at the positive z axis).
  public var yaw: Float
  
  /// Creates a new entity head yaw component.
  public init(_ yaw: Float) {
    self.yaw = yaw
  }
}
