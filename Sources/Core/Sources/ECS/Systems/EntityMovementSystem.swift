import FirebladeECS

/// Updates the position of each entity according to its velocity (excluding the player,
/// because velocity for the player is handled by the ``PlayerVelocitySystem-30ewl``).
public struct EntityMovementSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    let physicsEntities = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityRotation.self,
      EntityLerpState.self,
      EntityKindId.self,
      EntityOnGround.self,
      excludesAll: ClientPlayerEntity.self
    )

    for (position, velocity, rotation, lerpState, kind, onGround) in physicsEntities {
      guard let kind = RegistryStore.shared.entityRegistry.entity(withId: kind.id) else {
        log.warning("Unknown entity kind '\(kind.id)'")
        continue
      }

      if let (newPosition, newPitch, newYaw) = lerpState.tick(position: position.vector, pitch: rotation.pitch, yaw: rotation.yaw) {
        position.vector = newPosition
        rotation.pitch = newPitch
        rotation.yaw = newYaw
        return
      }

      velocity.vector *= 0.98

      if onGround.onGround {
        velocity.vector.y = 0
      } else {
        if kind.identifier == Identifier(name: "item") {
          velocity.vector.y *= 0.98
          velocity.vector.y -= 0.04
        }
      }

      if abs(velocity.vector.x) < 0.003 {
        velocity.vector.x = 0
      }
      if abs(velocity.vector.y) < 0.003 {
        velocity.vector.y = 0
      }
      if abs(velocity.vector.z) < 0.003 {
        velocity.vector.z = 0
      }

      position.move(by: velocity.vector)
    }
  }
}
