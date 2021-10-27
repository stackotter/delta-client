/// A component storing whether an entity is flying.
public struct EntityFlying {
  /// Whether the entity is flying or not.
  public var isFlying: Bool
  
  /// Creates an entity's flying state.
  /// - Parameter isFlying: Defaults to false.
  public init(_ isFlying: Bool = false) {
    self.isFlying = isFlying
  }
}
