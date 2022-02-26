import Foundation

/// A modifier for an entity attribute.
public struct EntityAttributeModifier {
  /// A unique identifier for the modifier (don't quite know how Minecraft uses it yet).
  public var uuid: UUID
  /// The amount to change the value by. The manner in which this affects the value is decided by ``operation``.
  public var amount: Double
  /// The operation used to apply the modifier.
  public var operation: Operation
  
  /// The operation used to apply a modifier.
  public enum Operation: UInt8 {
    /// Adds an amount to the value.
    case add = 0
    /// Increases the value by a percentage (in decimal form, not out of 100).
    case addPercent = 1
    /// Multiplies the value by an amount.
    case multiply = 2
  }
  
  /// Creates a new modifier.
  public init(uuid: UUID, amount: Double, operation: EntityAttributeModifier.Operation) {
    self.uuid = uuid
    self.amount = amount
    self.operation = operation
  }
}
