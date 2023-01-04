import Foundation
import FirebladeECS
import FirebladeMath

public struct PlayerAccelerationSystem: System {
  static let sneakMultiplier: Double = 0.3
  static let sprintingFoodLevel = 6

  static let sprintingModifier = EntityAttributeModifier(
    uuid: UUID(uuidString: "662A6B8D-DA3E-4C1C-8813-96EA6097278D")!,
    amount: 0.3,
    operation: .addPercent
  )

  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityNutrition.self,
      EntityFlying.self,
      EntityOnGround.self,
      EntityRotation.self,
      EntityPosition.self,
      EntityAcceleration.self,
      EntitySprinting.self,
      EntitySneaking.self,
      PlayerAttributes.self,
      EntityAttributes.self,
      PlayerCollisionState.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (
      nutrition,
      flying,
      onGround,
      rotation,
      position,
      acceleration,
      sprinting,
      sneaking,
      playerAttributes,
      entityAttributes,
      collisionState,
      _
    ) = family.next() else {
      log.error("PlayerAccelerationSystem failed to get player to tick")
      return
    }

    let inputState = nexus.single(InputState.self).component
    let inputs = Self.addControllerMovement(inputState.inputs, inputState.leftThumbstick)

    let forwardsImpulse: Double = inputs.contains(.moveForward) ? 1 : 0
    let backwardsImpulse: Double = inputs.contains(.moveBackward) ? 1 : 0
    let leftImpulse: Double = inputs.contains(.strafeLeft) ? 1 : 0
    let rightImpulse: Double = inputs.contains(.strafeRight) ? 1 : 0

    var impulse = Vec3d(
      leftImpulse - rightImpulse,
      0,
      forwardsImpulse - backwardsImpulse
    )

    if !flying.isFlying && inputs.contains(.sneak) {
      impulse *= Self.sneakMultiplier
      sneaking.isSneaking = true
    } else {
      sneaking.isSneaking = false
    }

    let canSprint = (nutrition.food > Self.sprintingFoodLevel || playerAttributes.canFly)
    if !sprinting.isSprinting && impulse.z >= 0.8 && canSprint && inputs.contains(.sprint) {
      sprinting.isSprinting = true
    }

    if sprinting.isSprinting {
      if !inputs.contains(.moveForward) || collisionState.collidingHorizontally {
        sprinting.isSprinting = false
      }
    }

    let hasModifier = entityAttributes[.movementSpeed].hasModifier(Self.sprintingModifier.uuid)
    if sprinting.isSprinting == true && !hasModifier {
      entityAttributes[.movementSpeed].apply(Self.sprintingModifier)
    } else if sprinting.isSprinting == false && hasModifier {
      entityAttributes[.movementSpeed].remove(Self.sprintingModifier.uuid)
    }

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
      onGround.onGround
    )

    impulse *= speed

    let rotationMatrix = MatrixUtil.rotationMatrix(y: Double(rotation.yaw))
    impulse = (Vec4d(impulse, 1) * rotationMatrix).xyz

    acceleration.vector = impulse
  }

  private static func addControllerMovement(
    _ inputs: Set<Input>,
    _ thumbstick: Vec2f
  ) -> Set<Input> {
    let x = thumbstick.x
    let y = thumbstick.y

    guard x != 0 || y != 0 else {
      return inputs
    }

    var inputs = inputs

    let angle = FirebladeMath.atan2(y, x)
    let sector = Int((angle / (.pi / 4)).rounded())
    if sector >= 1 && sector <= 3 {
      inputs.insert(.moveForward)
    }
    if sector >= -3 && sector <= -1 {
      inputs.insert(.moveBackward)
    }
    if sector == -4 || sector == -3 || sector == 3 || sector == 4 {
      inputs.insert(.strafeLeft)
    }
    if sector >= -1 && sector <= 1 {
      inputs.insert(.strafeRight)
    }

    return inputs
  }

  private static func calculatePlayerSpeed(
    _ position: Vec3d,
    _ world: World,
    _ movementSpeed: Double,
    _ isSprinting: Bool,
    _ onGround: Bool
  ) -> Double {
    var speed: Double
    if onGround {
      // TODO: make get block below function once there is a Position protocol (and make vectors conform to it)
      let blockPosition = BlockPosition(
        x: Int(Foundation.floor(position.x)),
        y: Int(Foundation.floor(position.y - 0.5)),
        z: Int(Foundation.floor(position.z))
      )
      let block = world.getBlock(at: blockPosition)
      let slipperiness = block.material.slipperiness

      speed = movementSpeed * 0.216 / (slipperiness * slipperiness * slipperiness)
    } else {
      speed = 0.02
      if isSprinting {
        speed += 0.006
      }
    }
    return speed
  }
}
