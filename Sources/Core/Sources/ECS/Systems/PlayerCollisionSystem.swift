import FirebladeECS
import FirebladeMath

// TODO: Implement pushoutofblocks method (see decompiled vanilla sources)
public struct PlayerCollisionSystem: System {
  static let stepHeight: Double = 0.6
  
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
      log.error("PlayerCollisionSystem failed to get player to tick")
      return
    }

    guard gamemode.gamemode.hasCollisions else {
      return
    }

    let original = velocity.vector
    let (adjustedVelocity, step) = Self.getAdjustedVelocityWithStepping(
      position.vector,
      velocity.vector,
      hitbox.aabb(at: position.vector),
      world,
      onGround.onGround
    )

    velocity.vector = adjustedVelocity
    position.vector.y += step

    onGround.onGround = original.y < 0 && original.y != velocity.y

    collisionState.collidingVertically = original.y != velocity.y
    collisionState.collidingHorizontally = original.x != velocity.x || original.z != velocity.z
  }

  /// Adjusts the player's velocity to avoid collisions while automatically going up blocks under
  /// 0.5 tall (e.g. slabs or carpets).
  /// - Parameters:
  ///   - position: The player's position.
  ///   - velocity: The player's velocity.
  ///   - aabb: The player's hitbox.
  ///   - world: The world the player is colliding with.
  /// - Returns: The adjusted velocity, the magnitude will be between 0 and the magnitude of the original velocity.
  private static func getAdjustedVelocityWithStepping(
    _ position: Vec3d,
    _ velocity: Vec3d,
    _ aabb: AxisAlignedBoundingBox,
    _ world: World,
    _ onGround: Bool
  ) -> (velocity: Vec3d, step: Double) {
    let adjustedVelocity = getAdjustedVelocity(position, velocity, aabb, world)

    let willBeOnGround = adjustedVelocity.y != velocity.y && velocity.y < 0
    let onGround = onGround || willBeOnGround
    let wasHorizontallyRestricted = adjustedVelocity.x != velocity.x || adjustedVelocity.z != velocity.z

    // Check if the player could step up to move further
    if onGround && wasHorizontallyRestricted {
      var velocityWithStep = getAdjustedVelocity(
        position,
        [velocity.x, Self.stepHeight, velocity.z],
        aabb,
        world
      )

      let maximumVerticalVelocity = getAdjustedVelocity(
        position,
        [0, Self.stepHeight, 0],
        aabb.extend(by: [velocity.x, 0, velocity.z]),
        world
      ).y

      if maximumVerticalVelocity < Self.stepHeight {
        // If the player would hit their head while ascending a full stepHeight, check if stepping as
        // high as possible without hitting their head would avoid other collisions.
        let velocityWithSmallerStep = getAdjustedVelocity(
          position,
          [velocity.x, 0, velocity.z],
          aabb.offset(by: maximumVerticalVelocity, along: .y),
          world
        )

        if velocityWithSmallerStep.horizontalMagnitude > velocityWithStep.horizontalMagnitude {
          velocityWithStep = velocityWithSmallerStep
          velocityWithStep.y = maximumVerticalVelocity
        }
      }

      if velocityWithStep.horizontalMagnitude > adjustedVelocity.horizontalMagnitude {
        // Recalculate the y velocity required to get up the 'step'.
        velocityWithStep += getAdjustedVelocity(position, [0, -Self.stepHeight, 0], aabb.offset(by: velocityWithStep), world)
        let step = velocityWithStep.y
        velocityWithStep.y = 0
        return (velocity: velocityWithStep, step: step)
      }
    }

    return (velocity: adjustedVelocity, step: 0)
  }

  /// Adjusts the player's velocity to avoid collisions.
  /// - Parameters:
  ///   - position: The player's position.
  ///   - velocity: The player's velocity.
  ///   - aabb: The player's hitbox.
  ///   - world: The world the player is colliding with.
  /// - Returns: The adjusted velocity, the magnitude will be between 0 and the magnitude of the original velocity.
  private static func getAdjustedVelocity(
    _ position: Vec3d,
    _ velocity: Vec3d,
    _ aabb: AxisAlignedBoundingBox,
    _ world: World
  ) -> Vec3d {
    let collisionVolume = getCollisionVolume(position, velocity, aabb, world)

    var adjustedVelocity = velocity

    adjustedVelocity.y = adjustComponent(adjustedVelocity.y, onAxis: .y, collisionVolume: collisionVolume, aabb: aabb)
    var adjustedAABB = aabb.offset(by: adjustedVelocity.y, along: .y)

    let prioritizeZ = abs(velocity.z) > abs(velocity.x)

    if prioritizeZ {
      adjustedVelocity.z = adjustComponent(adjustedVelocity.z, onAxis: .z, collisionVolume: collisionVolume, aabb: adjustedAABB)
      adjustedAABB = adjustedAABB.offset(by: adjustedVelocity.z, along: .z)
    }

    adjustedVelocity.x = adjustComponent(adjustedVelocity.x, onAxis: .x, collisionVolume: collisionVolume, aabb: adjustedAABB)
    adjustedAABB = adjustedAABB.offset(by: adjustedVelocity.x, along: .x)

    if !prioritizeZ {
      adjustedVelocity.z = adjustComponent(adjustedVelocity.z, onAxis: .z, collisionVolume: collisionVolume, aabb: adjustedAABB)
    }

    if adjustedVelocity.magnitudeSquared > velocity.magnitudeSquared {
      adjustedVelocity = .zero
    }

    return adjustedVelocity
  }

  /// Adjusts the specified component of the player velocity to avoid any collisions along that axis.
  /// - Parameters:
  ///   - value: The value of the velocity component.
  ///   - axis: The axis the velocity component lies on.
  ///   - collisionVolume: The volume to avoid collisions with.
  ///   - aabb: The player aabb.
  /// - Returns: The adjusted velocity along the given axis. The adjusted value will be between 0 and the original velocity.
  private static func adjustComponent(
    _ value: Double,
    onAxis axis: Axis,
    collisionVolume: CompoundBoundingBox,
    aabb: AxisAlignedBoundingBox
  ) -> Double {
    if abs(value) < 0.0000001 {
      return 0
    }

    var value = value
    for otherAABB in collisionVolume.aabbs {
      if !aabb.offset(by: value, along: axis).shrink(by: 0.001).intersects(with: otherAABB) {
        continue
      }

      let aabbMin = aabb.minimum.component(along: axis)
      let aabbMax = aabb.maximum.component(along: axis)
      let otherMin = otherAABB.minimum.component(along: axis)
      let otherMax = otherAABB.maximum.component(along: axis)

      if value > 0 && otherMin <= aabbMax + value {
        let newValue = otherMin - aabbMax
        if newValue >= -0.0000001 {
          value = min(newValue, value)
        }
      } else if value < 0 && otherMax >= aabbMin + value {
        let newValue = otherMax - aabbMin
        if newValue <= 0.0000001 {
          value = max(newValue, value)
        }
      }
    }
    return value
  }

  /// Gets a compound shape of all blocks the player could possibly be colliding with.
  ///
  /// It creates the smallest bounding box containing the current player AABB and the player AABB
  /// after adding the current velocity (pre-collisions). It then creates a compound bounding box
  /// containing all blocks within that volume.
  private static func getCollisionVolume(
    _ position: Vec3d,
    _ velocity: Vec3d,
    _ aabb: AxisAlignedBoundingBox,
    _ world: World
  ) -> CompoundBoundingBox {
    let nextAABB = aabb.offset(by: velocity)
    let minimum = MathUtil.min(aabb.minimum, nextAABB.minimum)
    let maximum = MathUtil.max(aabb.maximum, nextAABB.maximum)

    // Extend the AABB down one block to account for blocks such as fences
    let bigAABB = AxisAlignedBoundingBox(minimum: minimum, maximum: maximum).extend(.down, amount: 1)
    let blockPositions = bigAABB.blockPositions

    var collisionShape = CompoundBoundingBox()
    for blockPosition in blockPositions {
      guard world.isChunkComplete(at: blockPosition.chunk) else {
        continue
      }

      let block = world.getBlock(at: blockPosition)
      let blockShape = block.shape.collisionShape.offset(by: blockPosition.doubleVector)

      collisionShape.formUnion(blockShape)
    }

    return collisionShape
  }
}
