import FirebladeECS

public struct PlayerFlightSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: PlayerGamemode.self,
      EntityOnGround.self,
      EntityFlying.self,
      EntityVelocity.self,
      PlayerAttributes.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (gamemode, onGround, flying, velocity, attributes, _) = family.next() else {
      log.error("PlayerFlightSystem failed to get player to tick")
      return
    }
    
    let inputState = nexus.single(InputState.self).component
    
    if gamemode.gamemode.isAlwaysFlying {
      onGround.onGround = false
      flying.isFlying = true
    } else if onGround.onGround || !attributes.canFly {
      flying.isFlying = false
    }
    
    if flying.isFlying {
      let sneakPressed = inputState.inputs.contains(.sneak)
      let jumpPressed = inputState.inputs.contains(.jump)
      if sneakPressed != jumpPressed {
        if sneakPressed {
          velocity.y = Double(-attributes.flyingSpeed * 3)
        } else {
          velocity.y = Double(attributes.flyingSpeed * 3)
        }
      }
    }
  }
}
