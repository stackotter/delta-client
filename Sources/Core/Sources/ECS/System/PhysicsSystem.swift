import Foundation
import FirebladeECS
import simd

/// The system that handles entity physics.
public class PhysicsSystem: System {
  private var world: World
  private var worldLock = ReadWriteLock()
  
  /// Creates a simple physics system.
  public init(world: World) {
    self.world = world
  }
  
  /// Runs a physics update for all entities in the given Nexus.
  public func update(_ nexus: Nexus) {
    // Update the player's velocity.
    let currentPlayerEntities = nexus.family(
      requiresAll: EntityPosition.self,
      EntityHitBox.self,
      EntityVelocity.self,
      EntityRotation.self,
      PlayerInput.self,
      PlayerGamemode.self,
      EntityFlying.self,
      PlayerAttributes.self,
      ClientPlayerEntity.self)
    
    for (position, hitbox, velocity, rotation, inputs, gamemode, flying, attributes, _) in currentPlayerEntities {
      updatePlayerVelocity(velocity: velocity, rotation: rotation, input: inputs, gamemode: gamemode, flying: flying, attributes: attributes)
      handleCollisions(position, velocity, hitbox)
    }
    
    // Apply velocity to all moving entities.
    let physicsEntities = nexus.family(requiresAll: EntityPosition.self, EntityVelocity.self)
    for (position, velocity) in physicsEntities {
      position.move(by: velocity.vector)
    }
  }
  
  public func setWorld(_ world: World) {
    worldLock.acquireWriteLock()
    defer { worldLock.unlock() }
    self.world = world
  }
  
  func updatePlayerVelocity(
    velocity: EntityVelocity,
    rotation: EntityRotation,
    input: PlayerInput,
    gamemode: PlayerGamemode,
    flying: EntityFlying,
    attributes: PlayerAttributes
  ) {
    // TODO: Implement sprinting
    // TODO: Properly calculate these constants
    let frictionMultiplier = 0.91
    let airResistanceMultiplier = 0.98 // This one is just hardcoded
    
    // TODO: move this to some sort of gamemode system
    if gamemode.gamemode.isAlwaysFlying {
      flying.isFlying = true
    } else if !attributes.canFly {
      flying.isFlying = false
    }
    
    var velocityVector = input.getVector(isFlying: flying.isFlying)
    velocityVector *= airResistanceMultiplier
    
    var magnitude = simd_length_squared(velocityVector)
    if magnitude < 0.0000001 {
      velocityVector = SIMD3<Double>(repeating: 0)
      magnitude = 0
    }
    
    if magnitude > 1 {
      velocityVector = normalize(velocityVector)
    }
    
    // Adjust velocity to point in the right direction
    let rotationMatrix = MatrixUtil.rotationMatrix(y: Double(rotation.yaw))
    velocityVector = simd_make_double3(SIMD4<Double>(velocityVector, 1) * rotationMatrix)
    
    velocityVector *= Double(attributes.flyingSpeed)
    velocityVector += velocity.vector
    
    if flying.isFlying {
      let jumpPressed = input.inputs.contains(.jump)
      let sneakPressed = input.inputs.contains(.sneak)
      if jumpPressed != sneakPressed {
        if jumpPressed {
          velocityVector.y = Double(attributes.flyingSpeed * 3)
        } else {
          velocityVector.y = -Double(attributes.flyingSpeed * 3)
        }
      } else {
        velocityVector.y = 0
      }
    }
    
    velocityVector *= SIMD3(frictionMultiplier, airResistanceMultiplier, frictionMultiplier)
    
    // Update the player's velocity
    velocity.vector = velocityVector
  }
  
  func handleCollisions(_ position: EntityPosition, _ velocity: EntityVelocity, _ hitbox: EntityHitBox) {
    let positionVector = position.vector
    let velocityVector = velocity.vector
    let aabb = hitbox.aabb(at: positionVector)
    
    let collisionVolume = getCollisionVolume(positionVector, velocityVector, aabb)
    adjustVelocity(velocity, collisionVolume, aabb)
  }
  
  func adjustVelocity(_ velocity: EntityVelocity, _ collisionVolume: CompoundBoundingBox, _ aabb: AxisAlignedBoundingBox) {
    var adjustedVelocity = velocity.vector
    
    adjustedVelocity.y = adjustComponent(adjustedVelocity.y, onAxis: .y, collisionVolume: collisionVolume, aabb: aabb)
    var adjustedAABB = aabb.offset(by: adjustedVelocity.y, along: .y)
    
    let prioritizeZ = velocity.z > velocity.x
    
    if prioritizeZ {
      adjustedVelocity.z = adjustComponent(adjustedVelocity.z, onAxis: .z, collisionVolume: collisionVolume, aabb: adjustedAABB)
      adjustedAABB = adjustedAABB.offset(by: adjustedVelocity.z, along: .z)
    }
    
    adjustedVelocity.x = adjustComponent(adjustedVelocity.x, onAxis: .x, collisionVolume: collisionVolume, aabb: adjustedAABB)
    adjustedAABB = adjustedAABB.offset(by: adjustedVelocity.x, along: .x)
    
    if !prioritizeZ {
      adjustedVelocity.z = adjustComponent(adjustedVelocity.z, onAxis: .z, collisionVolume: collisionVolume, aabb: adjustedAABB)
    }
    
    if adjustedVelocity.magnitudeSquared > velocity.vector.magnitudeSquared {
      adjustedVelocity = .zero
    }
    
    if adjustedVelocity.x != velocity.x {
      velocity.x = 0
    }
    if adjustedVelocity.y != velocity.y {
      velocity.y = 0
    }
    if adjustedVelocity.z != velocity.z {
      velocity.z = 0
    }
  }
  
  func adjustComponent(_ value: Double, onAxis axis: Axis, collisionVolume: CompoundBoundingBox, aabb: AxisAlignedBoundingBox) -> Double {
    if abs(value) < 0.0000001 {
      return 0
    }
    
    var value = value
    for otherAABB in collisionVolume.aabbs {
      if !aabb.offset(by: value, along: axis).intersects(with: aabb) {
        continue
      }
      
      let aabbMin = aabb.minimum.component(along: axis)
      let aabbMax = aabb.maximum.component(along: axis)
      let otherMin = otherAABB.minimum.component(along: axis)
      let otherMax = otherAABB.maximum.component(along: axis)
      
      if value > 0 && otherMin <= aabbMax + value {
        value = min(otherMin - aabbMax, value)
      } else if value < 0 && otherMax >= aabbMin + value {
        value = max(otherMax - aabbMin, value)
      }
    }
    return value
  }
  
  func getCollisionVolume(_ position: SIMD3<Double>, _ velocity: SIMD3<Double>, _ aabb: AxisAlignedBoundingBox) -> CompoundBoundingBox {
    worldLock.acquireReadLock()
    defer { worldLock.unlock() }
    
    // Extend the AABB down one block to account for blocks such as fences
    let blockPositions = aabb.offset(by: velocity).grow(by: 0.001).extend(.down, amount: 1).blockPositions
    let previousBlockPositions = aabb.shrink(by: 1E-7).blockPositions
    
    var collisionShape = CompoundBoundingBox()
    for blockPosition in blockPositions {
      guard world.isChunkComplete(at: blockPosition.chunk) else {
        continue
      }
      
      let block = world.getBlock(at: blockPosition)
      let blockShape = block.shape.collisionShape.offset(by: blockPosition.doubleVector)
      
      if previousBlockPositions.contains(blockPosition) && blockShape.intersects(with: aabb) {
        continue
      }
      
      collisionShape.formUnion(blockShape)
    }
    
    return collisionShape
  }
}
