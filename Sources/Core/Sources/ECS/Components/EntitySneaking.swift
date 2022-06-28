import FirebladeECS

/// A component storing whether an entity is sneaking or not.
public class EntitySneaking: Component {
  /// Whether the entity is sneaking or not.
  public var isSneaking: Bool

  /// Creates an entity's sneaking state.
  /// - Parameter isSneaking: Defaults to false.
  public init(_ isSneaking: Bool = false) {
    self.isSneaking = isSneaking
  }
}
