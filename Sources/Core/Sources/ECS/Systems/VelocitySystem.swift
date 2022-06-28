import FirebladeECS

/// Updates the position of each entity according to its velocity (excluding the player,
/// because velocity for the player is handled by the ``PlayerVelocitySystem-30ewl``).
public struct VelocitySystem: System {
  /// Updates each entity's position according to its velocity.
  public func update(_ nexus: Nexus, _ world: World) {
    // Apply velocity to all moving entities (excluding the player).
    let physicsEntities = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityOnGround.self,
      excludesAll: ClientPlayerEntity.self
    )

    for (position, velocity, onGround) in physicsEntities {
      if onGround.onGround {
        velocity.vector.y = 0
      }

      position.save()
      position.move(by: velocity.vector)
    }
  }
}
