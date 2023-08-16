import FirebladeECS

public struct PlayerClimbSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      PlayerGamemode.self,
      PlayerCollisionState.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (position, velocity, gamemode, collisionState, _) = family.next() else {
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

    let block = world.getBlock(at: position.block)

    if block.isClimbable {
      return true
    } else {
      // If the player is on an open trapdoor above a ladder then they're also counted as being on a ladder
      // as long as the ladder and trapdoor are facing the same way.
      let blockBelow = world.getBlock(at: position.block.neighbour(.down))
      let blockIdentifierBelow = blockBelow.identifier

      let ladder = Identifier(name: "block/ladder")
      let onTrapdoorAboveLadder = block.className == "TrapdoorBlock" && blockIdentifierBelow == ladder
      let blocksFacingSameDirection = block.stateProperties.facing == blockBelow.stateProperties.facing
      let trapdoorIsOpen = block.stateProperties.isOpen == true
      return onTrapdoorAboveLadder && blocksFacingSameDirection && trapdoorIsOpen
    }
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
