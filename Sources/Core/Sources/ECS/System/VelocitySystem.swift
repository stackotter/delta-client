import FirebladeECS

/// Updates the position of each entity according to its velocity (excluding the player, because physics for the player is handled by the ``PlayerPhysicsSystem``.
public struct VelocitySystem: System {
  /// Updates each entity's position according to its velocity.
  public func update(_ nexus: Nexus, _ world: World) {
    // Apply velocity to all moving entities (excluding the player).
    let physicsEntities = nexus.family(requiresAll: EntityPosition.self, EntityVelocity.self, excludesAll: ClientPlayerEntity.self)
    for (position, velocity) in physicsEntities {
      position.move(by: velocity.vector)
    }
  }
}
