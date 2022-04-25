import FirebladeECS
import Foundation

public struct PlayerGravitySystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityFlying.self,
      EntityVelocity.self,
      EntityPosition.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (flying, velocity, position, _) = family.next() else {
      log.error("PlayerGravitySystem failed to get player to tick")
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
