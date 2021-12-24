import FirebladeECS

/// A component storing the player's current keyboard inputs.
public class PlayerInput: Component {
  /// The player's current keyboard inputs.
  public var inputs: Set<Input> = []
  
  /// Creates an empty input state.
  public init() {}
  
  /// - Parameter isFlying: Whether the player is flying (spectator mode style flying not elytra) or not.
  /// - Returns: A vector representing the user's input.
  public func getVector(isFlying: Bool) -> SIMD3<Double> {
    let isSneaking = !isFlying && inputs.contains(.sneak)
    
    var velocityVector = SIMD3<Double>(0, 0, 0)
    
    if !(inputs.contains(.moveForward) && inputs.contains(.moveBackward)) {
      if inputs.contains(.moveForward) {
        velocityVector.z = 1
      } else if inputs.contains(.moveBackward) {
        velocityVector.z = -1
      }
    }
    
    if !(inputs.contains(.strafeLeft) && inputs.contains(.strafeRight)) {
      if inputs.contains(.strafeLeft) {
        velocityVector.x = 1
      } else if inputs.contains(.strafeRight) {
        velocityVector.x = -1
      }
    }
    
    if isFlying {
      if !(inputs.contains(.jump) && inputs.contains(.sneak)) {
        if inputs.contains(.jump) {
          velocityVector.y = 1
        } else if inputs.contains(.sneak) {
          velocityVector.y = -1
        }
      }
    }
    
    return velocityVector
  }
}
