/// An entity's health (hp).
public struct EntityHealth {
  /// The entity's health measured in half hearts.
  public var health: Float
  
  /// Creates an entity's health value.
  /// - Parameter health: Defaults to 20 hp.
  public init(_ health: Float = 20) {
    self.health = health
  }
}
