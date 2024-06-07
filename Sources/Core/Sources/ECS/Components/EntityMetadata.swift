import FirebladeECS

/// The distinction between entity metadata and entity attributes is that entity
/// attributes are for properties that can have modifiers applied (e.g. speed,
/// max health, etc).
public class EntityMetadata: Component {
  /// If an entity doesn't have AI, we should ignore its velocity. For some reason the
  /// server still sends us the velocity even when the entity isn't moving.
  public var noAI = false

  public init() {}
}
