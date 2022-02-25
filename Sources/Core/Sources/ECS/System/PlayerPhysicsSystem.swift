import Foundation
import FirebladeECS
import simd

/// The system that handles physics for the client's player.
public struct PlayerPhysicsSystem: System {
  /// Updates the player's position and velocity according to friction and collisions.
  public func update(_ nexus: Nexus, _ world: World) {
    var familyIterator = nexus.family(
      requiresAll: EntityPosition.self,
      EntityHitBox.self,
      EntityVelocity.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, hitbox, velocity, onGround, _) = familyIterator.next() else {
      log.error("Failed to get player entity to handle input for")
      return
    }
    
    applyFriction(velocity)
    updatePositionAndVelocity(position, velocity, hitbox, onGround, world)
  }
  
  /// Applies air resistance along the y axis and friction along the x and z axes.
  /// - Parameter velocity: The player's velocity.
  private func applyFriction(_ velocity: EntityVelocity) {
    velocity.vector *= SIMD3(PhysicsConstants.frictionMultiplier, PhysicsConstants.airResistanceMultiplier, PhysicsConstants.frictionMultiplier)
  }
  
  /// Updates the player's position after adjusting the velocity. And sets velocity along any colliding axes to 0.
  /// - Parameters:
  ///   - position: The player's position.
  ///   - velocity: The player's velocity.
  ///   - hitbox: The player's hitbox.
  ///   - onGround: The component storing whether the player is on the ground.
  ///   - world: The world to check for collisions with.
  private func updatePositionAndVelocity(_ position: EntityPosition, _ velocity: EntityVelocity, _ hitbox: EntityHitBox, _ onGround: EntityOnGround, _ world: World) {
    let aabb = hitbox.aabb(at: position.vector)
    let adjustedVelocity = getAdjustedVelocity(position.vector, velocity.vector, aabb, world)
    
    position.move(by: adjustedVelocity)
    
    if adjustedVelocity.x != velocity.x {
      velocity.x = 0
    }
    
    if adjustedVelocity.y != velocity.y {
      velocity.y = 0
      onGround.onGround = true
    } else {
      onGround.onGround = false
    }
    
    if adjustedVelocity.z != velocity.z {
      velocity.z = 0
    }
  }
  
  /// Adjusts the player's velocity to avoid collisions.
  /// - Parameters:
  ///   - position: The player's position.
  ///   - velocity: The player's velocity.
  ///   - hitbox: The player's hitbox.
  /// - Returns: The adjusted velocity, the magnitude will be between 0 and the magnitude of the original velocity.
  private func getAdjustedVelocity(_ position: SIMD3<Double>, _ velocity: SIMD3<Double>, _ aabb: AxisAlignedBoundingBox, _ world: World) -> SIMD3<Double> {
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
  private func adjustComponent(_ value: Double, onAxis axis: Axis, collisionVolume: CompoundBoundingBox, aabb: AxisAlignedBoundingBox) -> Double {
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
        } else if axis == .y {
          print("Disregarded correction of \(newValue), original: \(value) on y axis")
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
  private func getCollisionVolume(_ position: SIMD3<Double>, _ velocity: SIMD3<Double>, _ aabb: AxisAlignedBoundingBox, _ world: World) -> CompoundBoundingBox {
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
