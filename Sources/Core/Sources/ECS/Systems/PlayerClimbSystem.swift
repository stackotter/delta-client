import FirebladeECS

public struct PlayerClimbSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityHitBox.self,
      EntityOnGround.self,
      PlayerGamemode.self,
      PlayerCollisionState.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (position, velocity, hitbox, onGround, gamemode, collisionState, _) = family.next() else {
      log.error("PlayerClimbSystem failed to get player to tick")
      return
    }

    let isOnLadder = Self.isOnLadder(position, world, gamemode.gamemode)

    guard isOnLadder else {
      return
    }

    let inputState = nexus.single(InputState.self).component

    // Limit horizontal velocity while on ladder.
    velocity.vector.x = MathUtil.clamp(velocity.vector.x, -0.15, 0.15)
    velocity.vector.z = MathUtil.clamp(velocity.vector.z, -0.15, 0.15)

    // Limit falling speed while on ladder.
    velocity.vector.y = max(velocity.vector.y, -0.15)
    
    // Ascending ladders takes precedence over sneaking on ladders.
    if collisionState.collidingHorizontally || inputState.inputs.contains(.jump) {
      velocity.vector.y = 0.2
    } else if Self.isStoppedOnLadder(position, world, gamemode.gamemode, inputState, collisionState) {
      velocity.vector.y = 0
    }
  }

  static func isOnLadder(_ position: EntityPosition, _ world: World, _ gamemode: Gamemode) -> Bool {
    guard gamemode != .spectator else {
      return false
    }

    let blockIdentifier = world.getBlock(at: position.block).identifier
    return blockIdentifier == Identifier(name: "block/ladder")
  }

  static func isStoppedOnLadder(
    _ position: EntityPosition,
    _ world: World,
    _ gamemode: Gamemode,
    _ inputState: InputState,
    _ collisionState: PlayerCollisionState
  ) -> Bool {
    let isClimbing = collisionState.collidingHorizontally || inputState.inputs.contains(.jump)
    return isOnLadder(position, world, gamemode) && !isClimbing && inputState.inputs.contains(.sneak)
  }
}
