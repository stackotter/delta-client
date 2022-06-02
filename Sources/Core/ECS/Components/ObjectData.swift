import FirebladeECS

/// A component storing an object's data value.
public class ObjectData: Component {
  /// The object's data value (don't ask me what this does, I don't know yet).
  public var data: Int
  
  /// Creates an object data component.
  public init(_ data: Int) {
    self.data = data
  }
}
