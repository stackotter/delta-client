import FirebladeECS

/// An idea stolen from Rust to add reference semantics to a value type. Because most components don't actually make sense as reference types.
public class Box<T>: Component {
  public var value: T
  
  public init(_ initialValue: T) {
    value = initialValue
  }
}
