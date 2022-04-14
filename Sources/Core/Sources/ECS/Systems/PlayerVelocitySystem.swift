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
    
    var multiplier: Double = 0.91
    if onGround.onGround {
      let blockPosition = BlockPosition(
        x: Int(position.x.rounded(.down)),
        y: Int((position.y - 0.5).rounded(.down)),
        z: Int(position.z.rounded(.down)))
      let material = world.getBlock(at: blockPosition).material

      multiplier *= Double(material.velocityMultiplier * material.slipperiness)
    }

    velocity.x *= multiplier
    velocity.z *= multiplier
  }
}
