import FirebladeECS

/// A component storing the id of an entity's kind.
public class EntityKindId: Component {
  public var id: Int
  
  public init(_ id: Int) {
    self.id = id
  }
}
