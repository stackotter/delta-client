import FirebladeECS

/// A component storing the id of an entity's kind.
public class EntityKindId: Component {
  public var id: Int

  public var entityKind: EntityKind? {
    RegistryStore.shared.entityRegistry.entity(withId: id)
  }
  
  public init(_ id: Int) {
    self.id = id
  }
}
