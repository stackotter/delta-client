import FirebladeECS
import Foundation

public struct PlayerGravitySystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityFlying.self,
      EntityPosition.self,
      EntityVelocity.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (flying, position, velocity, _) = family.next() else {
      log.error("PlayerGravitySystem failed to get player to tick")
      return
    }
    
    guard !flying.isFlying else {
      return
    }
    
    velocity.y -= 0.08
    velocity.y *= 0.98

    print("position: (\(position.x), \(position.y), \(position.z))")
    print("velocity: (\(velocity.x), \(velocity.y), \(velocity.z))")
  }
}
