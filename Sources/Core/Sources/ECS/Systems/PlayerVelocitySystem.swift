import FirebladeECS

public struct PlayerVelocitySystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityAcceleration.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, velocity, acceleration, onGround, _) = family.next() else {
      log.error("PlayerVelocitySystem failed to get player to tick")
      return
    }
    
    // velocity.vector *= 0.98
    
    if abs(velocity.x) < 0.003 {
      velocity.x = 0
    }
    if abs(velocity.y) < 0.003 {
      velocity.y = 0
    }
    if abs(velocity.z) < 0.003 {
      velocity.z = 0
    }
    
    velocity.vector += acceleration.vector
  }
}
