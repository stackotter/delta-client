import FirebladeECS
import simd

public struct PlayerAccelerationSystem: System {
  static let sneakMultiplier: Double = 0.3
  static let sprintingFoodLevel = 6
  
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityNutrition.self,
      EntityFlying.self,
      EntityOnGround.self,
      EntityRotation.self,
      EntityPosition.self,
      EntityAcceleration.self,
      EntitySprinting.self,
      PlayerAttributes.self,
      EntityAttributes.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (nutrition, flying, onGround, rotation, position, acceleration, sprinting, playerAttributes, entityAttributes, _) = family.next() else {
      log.error("PlayerAccelerationSystem failed to get player to tick")
      return
    }
    
    let inputState = nexus.single(InputState.self).component
    let inputs = inputState.inputs
    
    let forwardsImpulse: Double = inputs.contains(.moveForward) ? 1 : 0
    let backwardsImpulse: Double = inputs.contains(.moveBackward) ? 1 : 0
    let leftImpulse: Double = inputs.contains(.strafeLeft) ? 1 : 0
    let rightImpulse: Double = inputs.contains(.strafeRight) ? 1 : 0
    
    var impulse = SIMD3<Double>(
      leftImpulse - rightImpulse,
      0,
      forwardsImpulse - backwardsImpulse)
    
    if !flying.isFlying && inputs.contains(.sneak) {
      impulse *= Self.sneakMultiplier
    }
    
    sprinting.isSprinting = impulse.z >= 0.8 && (nutrition.food > Self.sprintingFoodLevel || playerAttributes.canFly) && inputs.contains(.sprint)

    if impulse.magnitude < 0.0000001 {
      impulse = .zero
    } else if impulse.magnitudeSquared > 1 {
      impulse = normalize(impulse)
    }

    impulse.x *= 0.98
    impulse.z *= 0.98
    
    let speed = Self.calculatePlayerSpeed(
      position.vector,
      world,
      entityAttributes[.movementSpeed].value,
      sprinting.isSprinting,
      onGround.onGround)

    impulse *= speed
    
    let rotationMatrix = MatrixUtil.rotationMatrix(y: Double(rotation.yaw))
    impulse = simd_make_double3(SIMD4<Double>(impulse, 1) * rotationMatrix)
    
    acceleration.vector = impulse
  }
  
  private static func calculatePlayerSpeed(
    _ position: SIMD3<Double>,
    _ world: World,
    _ movementSpeed: Double,
    _ isSprinting: Bool,
    _ onGround: Bool
  ) -> Double {
    var speed: Double
    if onGround {
      // TODO: make get block below function once there is a Position protocol (and make vectors conform to it)
      let blockPosition = BlockPosition(
        x: Int(floor(position.x)),
        y: Int(floor(position.y - 0.5)),
        z: Int(floor(position.z)))
      let block = world.getBlock(at: blockPosition)
      let slipperiness = block.material.slipperiness
      
      speed = movementSpeed * 0.216 / (slipperiness * slipperiness * slipperiness)
      if isSprinting {
        speed *= 1.3
      }
    } else {
      speed = 0.02
      if isSprinting {
        speed += 0.006
      }
    }
    return speed
  }
}
