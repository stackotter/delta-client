import FirebladeECS

/// A component storing whether an entity is on the ground (walking or swimming) or not on the ground (jumping/falling).
public class EntityOnGround: Component {
  /// Whether the entity is touching the ground or not.
  public var onGround: Bool
  /// The most recently saved value of ``onGround`` (see ``save()``).
  public var previousOnGround: Bool
  
  public init(_ onGround: Bool) {
    self.onGround = onGround
    previousOnGround = onGround
  }

  /// Saves the current value to ``previousOnGround``.
  public func save() {
    previousOnGround = onGround
  }
}
