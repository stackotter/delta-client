import FirebladeECS
import simd

public struct PlayerCollisionSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityVelocity.self,
      EntityHitBox.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, velocity, hitbox, onGround, _) = family.next() else {
      log.error("PlayerCollisionSystem failed to get player to tick")
      return
    }
    
    let original = velocity.vector
    velocity.vector = Self.getAdjustedVelocity(
      position.vector,
      velocity.vector,
      hitbox.aabb(at: position.vector),
      world)
    
    if original.y < 0 && original.y != velocity.y {
      onGround.onGround = true
    } else {
      onGround.onGround = false
    }
  }
  
  /// Adjusts the player's velocity to avoid collisions.
  /// - Parameters:
  ///   - position: The player's position.
  ///   - velocity: The player's velocity.
  ///   - hitbox: The player's hitbox.
  /// - Returns: The adjusted velocity, the magnitude will be between 0 and the magnitude of the original velocity.
  private static func getAdjustedVelocity(
    _ position: SIMD3<Double>,
    _ velocity: SIMD3<Double>,
    _ aabb: AxisAlignedBoundingBox,
    _ world: World
  ) -> SIMD3<Double> {
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
  private static func adjustComponent(_ value: Double, onAxis axis: Axis, collisionVolume: CompoundBoundingBox, aabb: AxisAlignedBoundingBox) -> Double {
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
  private static func getCollisionVolume(_ position: SIMD3<Double>, _ velocity: SIMD3<Double>, _ aabb: AxisAlignedBoundingBox, _ world: World) -> CompoundBoundingBox {
    let nextAABB = aabb.offset(by: velocity)
    let minimum = min(aabb.minimum, nextAABB.minimum)
    let maximum = max(aabb.maximum, nextAABB.maximum)
    
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
