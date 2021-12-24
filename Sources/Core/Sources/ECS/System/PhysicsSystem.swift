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
    // Update the player's velocity.
    let currentPlayerEntities = nexus.family(requiresAll: EntityVelocity.self, EntityRotation.self, PlayerInputs.self, PlayerGamemode.self, ClientPlayerEntity.self)
    for (velocity, rotation, inputs, gamemode, _) in currentPlayerEntities {
      updatePlayer(velocity: velocity, rotation: rotation, inputs: inputs, gamemode: gamemode)
    }
    
    // Apply velocity to all moving entities.
    let physicsEntities = nexus.family(requiresAll: EntityPosition.self, EntityVelocity.self)
    for (position, velocity) in physicsEntities {
      position.move(by: velocity.vector)
    }
  }
  
  func updatePlayer(
    velocity: EntityVelocity,
    rotation: EntityRotation,
    inputs: PlayerInputs,
    gamemode: PlayerGamemode
  ) {
    let inputs = input.inputs
    
    // Update velocity relative to yaw
    var velocityVector = SIMD3<Double>(0, 0, 0)
    if inputs.contains(.moveForward) {
      velocityVector.z = playerSpeed
    } else if inputs.contains(.moveBackward) {
      velocityVector.z = -playerSpeed
    }
    
    if inputs.contains(.strafeLeft) {
      velocityVector.x = playerSpeed
    } else if inputs.contains(.strafeRight) {
      velocityVector.x = -playerSpeed
    }
    
    if inputs.contains(.jump) {
      velocityVector.y = playerSpeed
    } else if inputs.contains(.sneak) {
      velocityVector.y = -playerSpeed
    }
    
    if inputs.contains(.sprint) {
      velocityVector *= 2
    }
    
    // Adjust velocity to point in the right direction (using yaw)
    let yawRadians = Double(rotation.yaw * .pi / 180)
    var xz = SIMD2<Double>(velocityVector.x, velocityVector.z)
    // swiftlint:disable shorthand_operator
    xz = xz * MatrixUtil.rotationMatrix2dDouble(yawRadians)
    // swiftlint:enable shorthand_operator
    velocityVector.x = xz.x
    velocityVector.z = xz.y // z is the 2nd component of xz (aka y)
    velocity.vector = velocityVector
  }
}
