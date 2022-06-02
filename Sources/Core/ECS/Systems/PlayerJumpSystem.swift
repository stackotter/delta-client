import Foundation
import FirebladeECS

public struct PlayerJumpSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityOnGround.self,
      EntitySprinting.self,
      EntityVelocity.self,
      EntityPosition.self,
      EntityRotation.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (onGround, sprinting, velocity, position, rotation, _) = family.next() else {
      log.error("PlayerJumpSystem failed to get player to tick")
      return
    }
    
    let inputState = nexus.single(InputState.self).component
    
    guard onGround.onGround && inputState.inputs.contains(.jump) else {
      return
    }
    
    let blockPosition = BlockPosition(
      x: Int(position.x.rounded(.down)),
      y: Int((position.y - 0.5).rounded(.down)),
      z: Int(position.z.rounded(.down))
    )
    let block = world.getBlock(at: blockPosition)
    
    let jumpPower = 0.42 * Double(block.material.jumpVelocityMultiplier)
    velocity.y = jumpPower
    
    // Add a bit of extra acceleration if the player is sprinting (this makes sprint jumping faster than sprinting)
    if sprinting.isSprinting {
      let yaw = Double(rotation.yaw)
      velocity.x -= sin(yaw) * 0.2
      velocity.z += cos(yaw) * 0.2
    }
  }
}
