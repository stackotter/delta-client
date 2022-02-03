import FirebladeECS

/// A component storing an entity's id.
public class EntityId: Component {
  public var id: Int
  
  public init(_ id: Int) {
    self.id = id
  }
}
