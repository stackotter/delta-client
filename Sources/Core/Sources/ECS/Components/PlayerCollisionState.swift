import FirebladeECS

/// A component which stores the state of collisions from the latest tick.
public class PlayerCollisionState: Component {
  public var collidingHorizontally = false
  public var collidingVertically = false

  public init() {}
}
