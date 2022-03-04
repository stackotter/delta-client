import FirebladeECS

/// A component storing whether an entity is sprinting or not.
public class EntitySprinting: Component {
  /// Whether the entity is sprinting or not.
  public var isSprinting: Bool
  
  /// Creates an entity's sprinting state.
  /// - Parameter isSprinting: Defaults to false.
  public init(_ isSprinting: Bool = false) {
    self.isSprinting = isSprinting
  }
}
