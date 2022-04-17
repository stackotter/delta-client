import FirebladeECS

public struct PlayerFrictionSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, velocity, onGround, _) = family.next() else {
      log.error("PlayerFrictionSystem failed to get player to tick")
      return
    }
    
    var multiplier: Double = 0.91
    if onGround.previousOnGround {
      let blockPosition = BlockPosition(
        x: Int(position.x.rounded(.down)),
        y: Int((position.y - 0.5).rounded(.down)),
        z: Int(position.z.rounded(.down)))
      let material = world.getBlock(at: blockPosition).material

      multiplier *= material.slipperiness
    }

    velocity.x *= multiplier
    velocity.z *= multiplier
  }
}
