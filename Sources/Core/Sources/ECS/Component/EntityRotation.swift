import FirebladeECS

/// A component storing an entity's rotation in radians.
public class EntityRotation: Component {
  /// Pitch in radians.
  public var pitch: Float
  /// Yaw in radians.
  public var yaw: Float
  
  /// Creates an entity's rotation.
  /// - Parameters:
  ///   - pitch: The pitch in radians. -pi/2 is straight up, 0 is straight ahead, and pi/2 is straight down.
  ///   - yaw: The yaw in radians. Measured counterclockwise from the positive z axis.
  public init(pitch: Float, yaw: Float) {
    self.pitch = pitch
    self.yaw = yaw
  }
}
