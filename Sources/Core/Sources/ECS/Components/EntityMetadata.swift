import FirebladeECS

/// The distinction between entity metadata and entity attributes is that entity
/// attributes are for properties that can have modifiers applied (e.g. speed,
/// max health, etc).
public class EntityMetadata: Component {
  /// Metadata specific to a certain kind of entity.
  public var specializedMetadata: SpecializedMetadata?

  public var itemMetadata: ItemMetadata? {
    switch specializedMetadata {
      case let .item(metadata): return metadata
      default: return nil
    }
  }

  public var mobMetadata: MobMetadata? {
    switch specializedMetadata {
      case let .mob(metadata): return metadata
      default: return nil
    }
  }

  public enum SpecializedMetadata {
    case item(ItemMetadata)
    case mob(MobMetadata)
  }

  public struct ItemMetadata {
    public var slot = Slot()
    /// The phase (in the periodic motion sense) of the item entity's bobbing animation.
    /// Not part of the vanilla entity metadata, this is just a sensible place to store
    /// this item entity property.
    public var bobbingPhaseOffset: Float

    public init() {
      bobbingPhaseOffset = Float.random(in: 0...1) * 2 * .pi
    }
  }

  public struct MobMetadata {
    /// If an entity doesn't have AI, we should ignore its velocity. For some reason the
    /// server still sends us the velocity even when the entity isn't moving.
    public var noAI = false
  }

  /// Creates a
  public init(inheritanceChain: [String]) {
    if inheritanceChain.contains("ItemEntity") {
      specializedMetadata = .item(ItemMetadata())
    } else if inheritanceChain.contains("MobEntity") {
      specializedMetadata = .mob(MobMetadata())
    }
  }
}
