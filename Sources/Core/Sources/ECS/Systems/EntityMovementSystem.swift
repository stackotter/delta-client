import FirebladeECS

/// Updates the position of each entity according to its velocity (excluding the player,
/// because velocity for the player is handled by the ``PlayerVelocitySystem-30ewl``).
public struct EntityMovementSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    let physicsEntities = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityOnGround.self,
      excludesAll: ClientPlayerEntity.self
    )

    for (position, velocity, onGround) in physicsEntities {
      if onGround.onGround {
        velocity.vector.y = 0
      } else {
        velocity.vector.y *= 0.98
        velocity.vector.y -= 0.04
      }

      position.move(by: velocity.vector)
    }
  }
}
