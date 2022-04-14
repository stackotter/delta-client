import FirebladeECS

public struct PlayerPositionSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, velocity, onGround, _) = family.next() else {
      log.error("PlayerPositionSystem failed to get player to tick")
      return
    }
    
    position.vector += velocity.vector
    
    position.x = MathUtil.clamp(position.x, -29_999_999, 29_999_999)
    position.z = MathUtil.clamp(position.z, -29_999_999, 29_999_999)
    
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
