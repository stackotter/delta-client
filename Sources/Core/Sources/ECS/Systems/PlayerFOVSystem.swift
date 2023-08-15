import Foundation
import FirebladeECS

public struct PlayerFOVSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: PlayerFOV.self,
      EntityAttributes.self,
      EntityFlying.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (fov, attributes, flying, _) = family.next() else {
      log.error("PlayerFOVSystem failed to get player to tick")
      return
    }

    // Save the current fov as the fov to smooth from over the course of the next tick.
    fov.save()

    let speedAttribute = attributes[EntityAttributeKey.movementSpeed]
    let speed = speedAttribute.value
    let baseSpeed = speedAttribute.baseValue

    var targetMultiplier: Float
    if baseSpeed != 0 && speed != 0 {
      targetMultiplier = Float((speed / baseSpeed + 1) / 2)
      if flying.isFlying {
        targetMultiplier *= 1.1
      }
    } else {
      targetMultiplier = 1
    }

    // The effective multiplier will creep up to the value of `targetMultiplier` over the
    // course of a few ticks.
    fov.multiplier += (targetMultiplier - fov.multiplier) / 2

    if fov.multiplier > 1.5 {
      fov.multiplier = 1.5
    } else if fov.multiplier < 0.1 {
      fov.multiplier = 0.1
    }
  }
}
