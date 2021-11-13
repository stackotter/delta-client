/// A component storing whether an entity is on the ground (walking or swimming) or not on the ground (jumping/falling).
public struct EntityOnGround {
  public var onGround: Bool
  
  public init(_ onGround: Bool) {
    self.onGround = onGround
  }
}
