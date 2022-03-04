import FirebladeECS

public struct PlayerPositionSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, velocity, _) = family.next() else {
      log.error("PlayerPositionSystem failed to get player to tick")
      return
    }
    
    position.vector += velocity.vector
    
    position.x = MathUtil.clamp(position.x, -29_999_999, 29_999_999)
    position.z = MathUtil.clamp(position.z, -29_999_999, 29_999_999)
  }
}
