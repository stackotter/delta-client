import Foundation

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
      value += modifier.amount * baseValue
    }

    let multiplicativeModifiers = modifiers.filter { $0.operation == .multiply }
    for modifier in multiplicativeModifiers {
      value *= modifier.amount + 1
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

  /// Gets whether this value has a given modifier.
  /// - Parameter uuid: The uuid of the modifier to check for.
  /// - Returns: `true` if the value has a modifier with the given uuid.
  public func hasModifier(_ uuid: UUID) -> Bool {
    for modifier in modifiers where modifier.uuid == uuid {
      return true
    }
    return false
  }

  /// Applies a modifier to the value.
  /// - Parameter modifier: The modifier to apply.
  public mutating func apply(_ modifier: EntityAttributeModifier) {
    if hasModifier(modifier.uuid) {
      remove(modifier.uuid)
    }
    modifiers.append(modifier)
  }

  /// Removes a modifier from the value if it exists.
  /// - Parameter uuid: The uuid of the modifier to remove.
  public mutating func remove(_ uuid: UUID) {
    modifiers = modifiers.filter { modifier in
      return modifier.uuid != uuid
    }
  }
}
