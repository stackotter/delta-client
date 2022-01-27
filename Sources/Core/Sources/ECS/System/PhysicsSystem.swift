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
    let currentPlayerEntities = nexus.family(requiresAll: EntityVelocity.self, EntityRotation.self, PlayerInput.self, PlayerGamemode.self, EntityFlying.self, PlayerAttributes.self, ClientPlayerEntity.self)
    for (velocity, rotation, inputs, gamemode, flying, attributes, _) in currentPlayerEntities {
      updatePlayerVelocity(velocity: velocity, rotation: rotation, input: inputs, gamemode: gamemode, flying: flying, attributes: attributes)
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
//    let isSneaking = !isFlying && inputs.contains(.sneak)
    
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
    
    collisionTest()
  }
  
  func collisionTest() {
    worldLock.acquireReadLock()
    defer { worldLock.unlock() }
  }
}
