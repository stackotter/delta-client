/// The value of an entity attribute.
public struct EntityAttributeValue {
  /// The value before applying ``modifiers``.
  public var baseValue: Double
  /// Modifiers that are currently affecting the value.
  public var modifiers: [EntityAttributeModifier]
  
  /// The value after applying ``modifiers``.
  public var value: Double {
    var value = baseValue
    
    let additiveModifiers = modifiers.filter { $0.operation == .add }
    for modifier in additiveModifiers {
      value += modifier.amount
    }
    
    let relativeAdditiveModifiers = modifiers.filter { $0.operation == .addPercent }
    for modifier in relativeAdditiveModifiers {
      value *= 1 + modifier.amount
    }
    
    let multiplicativeModifiers = modifiers.filter { $0.operation == .multiply }
    for modifier in multiplicativeModifiers {
      value *= modifier.amount
    }
    
    return value
  }
  
  /// Creates a new value.
  /// - Parameters:
  ///   - baseValue: The base value without modifiers applied.
  ///   - modifiers: The modifiers affecting the value. Defaults to none.
  public init(baseValue: Double, modifiers: [EntityAttributeModifier] = []) {
    self.baseValue = baseValue
    self.modifiers = modifiers
  }
}
