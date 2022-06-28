import FirebladeECS

/// Saves the position of each entity before it is modified so that interpolation can be performed
/// when rendering.
public struct EntitySmoothingSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    let physicsEntities = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      excludesAll: ClientPlayerEntity.self
    )

    for (position, _) in physicsEntities {
      position.save()
    }
  }
}
