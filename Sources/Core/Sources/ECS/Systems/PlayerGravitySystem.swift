import FirebladeECS
import Foundation

public struct PlayerGravitySystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityFlying.self,
      EntityVelocity.self,
      EntityPosition.self,
      PlayerGamemode.self,
      PlayerCollisionState.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (flying, velocity, position, gamemode, collisionState, _) = family.next() else {
      log.error("PlayerGravitySystem failed to get player to tick")
      return
    }

    let inputState = nexus.single(InputState.self).component

    guard !PlayerClimbSystem.isStoppedOnLadder(position, world, gamemode.gamemode, inputState, collisionState) else {
      return
    }
    
    guard !flying.isFlying else {
      return
    }

    if world.chunk(at: position.chunk) != nil {
      velocity.y -= 0.08
    }

    velocity.y *= 0.98
  }
}
