import FirebladeECS

/// A component storing an entity's attributes.
public class EntityAttributes: Component {
  /// The attributes as key-value pairs.
  private var attributes: [EntityAttributeKey: EntityAttributeValue] = [:]
  
  /// Creates a new component with the default value for each attribute.
  public init() {}
  
  /// Gets and sets the value of an attribute. If the attribute has no value, the default value is returned.
  public subscript(_ attribute: EntityAttributeKey) -> EntityAttributeValue {
    get {
      return attributes[attribute] ?? EntityAttributeValue(baseValue: attribute.defaultValue)
    }
    set(newValue) {
      attributes[attribute] = newValue
    }
  }
}
