import Foundation
import FirebladeECS
import simd

/// The system that handles entity physics.
public struct PhysicsSystem: System {
  // TODO: use an actual player speed value from a component or something
  /// Defaults player speed in blocks per tick
  public var playerSpeed: Double = 0.2
  
  /// Creates a default physics system.
  public init() {}
  
  /// Runs a physics update for all entities in the given Nexus.
  public func update(_ nexus: Nexus) {
    // Update the player's velocity
    let currentPlayerEntities = nexus.family(requiresAll: Box<EntityVelocity>.self, Box<EntityRotation>.self, Box<PlayerInput>.self, Box<ClientPlayerEntity>.self)
    for (velocity, rotation, input, _) in currentPlayerEntities {
      let inputs = input.value.inputs
      
      // TODO: update in physics system
      // update velocity relative to yaw
      var velocityVector = EntityVelocity(x: 0.0, y: 0.0, z: 0.0).vector
      if inputs.contains(.forward) {
        velocityVector.z = playerSpeed
      } else if inputs.contains(.backward) {
        velocityVector.z = -playerSpeed
      }
      
      if inputs.contains(.left) {
        velocityVector.x = playerSpeed
      } else if inputs.contains(.right) {
        velocityVector.x = -playerSpeed
      }
      
      if inputs.contains(.jump) {
        velocityVector.y = playerSpeed
      } else if inputs.contains(.shift) {
        velocityVector.y = -playerSpeed
      }
      
      if inputs.contains(.sprint) {
        velocityVector *= 2
      }
      
      // adjust to real velocity (using yaw)
      let yawRadians = Double(rotation.value.yaw * .pi / 180)
      var xz = SIMD2<Double>(velocityVector.x, velocityVector.z)
      // swiftlint:disable shorthand_operator
      xz = xz * MatrixUtil.rotationMatrix2dDouble(yawRadians)
      // swiftlint:enable shorthand_operator
      velocityVector.x = xz.x
      velocityVector.z = xz.y // z is the 2nd component of xz (aka y)
      velocity.value = EntityVelocity(velocityVector)
    }
    
    // Update all generic entities
    let physicsEntities = nexus.family(requiresAll: Box<EntityPosition>.self, Box<EntityTargetPosition>.self, Box<EntityVelocity>.self)
    for (position, targetPosition, velocity) in physicsEntities {
      position.value = targetPosition.value.position
      targetPosition.value.position.x += velocity.value.x
      targetPosition.value.position.y += velocity.value.y
      targetPosition.value.position.z += velocity.value.z
    }
  }
}
