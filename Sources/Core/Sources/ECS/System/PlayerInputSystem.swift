import Foundation
import FirebladeECS
import simd

/// The system that handles player input.
public struct PlayerInputSystem: System {
  /// Updates the player's rotation and velocity according to their current inputs.
  public func update(_ nexus: Nexus, _ world: World) {
    var familyIterator = nexus.family(
      requiresAll: EntityVelocity.self,
      EntityRotation.self,
      PlayerGamemode.self,
      EntityFlying.self,
      PlayerAttributes.self,
      EntityCamera.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (velocity, rotation, gamemode, flying, attributes, camera, onGround, _) = familyIterator.next() else {
      log.error("Failed to get player entity to handle input for")
      return
    }
    
    let inputState = nexus.single(InputState.self).component
    
    // Handle inputs
    updateRotation(inputState, rotation)
    updateCamera(inputState, camera)
    updateVelocity(inputState, velocity, rotation, gamemode, flying, onGround, attributes)
    
    // Flush input state for the next tick
    inputState.resetMouseDelta()
    inputState.flushInputs()
  }
  
  /// Updates the direction which the player is looking.
  /// - Parameters:
  ///   - inputState: The current input state.
  ///   - rotation: The player's rotation component.
  private func updateRotation(_ inputState: InputState, _ rotation: EntityRotation) {
    let mouseDelta = inputState.mouseDelta
    var yaw = rotation.yaw + mouseDelta.x
    var pitch = rotation.pitch + mouseDelta.y
    
    // Clamp pitch between -90 and 90
    pitch = MathUtil.clamp(pitch, -.pi / 2, .pi / 2)
    
    // Wrap yaw to be between 0 and 360
    let remainder = yaw.truncatingRemainder(dividingBy: .pi * 2)
    yaw = remainder < 0 ? .pi * 2 + remainder : remainder
    
    rotation.yaw = yaw
    rotation.pitch = pitch
  }
  
  /// Updates the player's camera perspective.
  /// - Parameters:
  ///   - inputState: The current input state.
  ///   - camera: The player's camera component.
  private func updateCamera(_ inputState: InputState, _ camera: EntityCamera) {
    if inputState.newlyPressed.contains(.changePerspective) {
      camera.cyclePerspective()
    }
  }
  
  /// Updates the player's velocity according to their current inputs.
  /// - Parameters:
  ///   - inputState: The current input state.
  ///   - velocity: The player's velocity component.
  ///   - rotation: The player's rotation component.
  ///   - gamemode: The player's gamemode component.
  ///   - flying: The player's flying component.
  ///   - onGround: The component storing whether the player is on the ground.
  ///   - attributes: The player's attributes component.
  private func updateVelocity(
    _ inputState: InputState,
    _ velocity: EntityVelocity,
    _ rotation: EntityRotation,
    _ gamemode: PlayerGamemode,
    _ flying: EntityFlying,
    _ onGround: EntityOnGround,
    _ attributes: PlayerAttributes
  ) {
    // Make suring the state of isFlying is allowed
    if gamemode.gamemode.isAlwaysFlying {
      flying.isFlying = true
    } else if !attributes.canFly {
      flying.isFlying = false
    }
    
    // Find horizontal acceleration from the input state
    var acceleration = getInputAcceleration(inputState.inputs, isFlying: flying.isFlying)
    
    // Apply air resistance (the first time, it's also applied later because that's what vanilla Minecraft does)
    acceleration *= PhysicsConstants.airResistanceMultiplier
    
    // Normalize the velocity if the magnitude is greater than 1 or set it to 0 if the magnitude is sufficiently small
    let magnitudeSquared = acceleration.magnitudeSquared
    if magnitudeSquared < 0.0000001 {
      acceleration = SIMD3.zero
    } else if magnitudeSquared > 1 {
      acceleration = normalize(acceleration)
    }
    
    // Adjust velocity to point in the correct direction
    let rotationMatrix = MatrixUtil.rotationMatrix(y: Double(rotation.yaw))
    acceleration = simd_make_double3(SIMD4<Double>(acceleration, 1) * rotationMatrix)
    
    // Apply sprinting modifier
    if inputState.inputs.contains(.sprint) {
      acceleration *= 1.3
    }
    
    // Multiply by speed
    let speed: Double
    if flying.isFlying {
      speed = Double(attributes.flyingSpeed)
    } else {
      // Load player entity properties from the server
      speed = 0.02
    }
    acceleration *= speed
    
    // Handle jumping and gravity if not flying
    if !flying.isFlying {
      if !onGround.onGround {
        acceleration.y = -0.08
      } else if inputState.inputs.contains(.jump) {
        // TODO: implement sprint jumping
        acceleration.y = 0.42
      }
    }
    
    // Apply acceleration
    var velocityVector = velocity.vector + acceleration
    
    // Apply vertical acceleration
    if flying.isFlying {
      let jumpPressed = inputState.inputs.contains(.jump)
      let sneakPressed = inputState.inputs.contains(.sneak)
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
    
    // Update the player's velocity
    velocity.vector = velocityVector
  }
  
  /// Gets the player's input acceleration (not rotated to face in the direction of movement).
  /// - Parameters:
  ///   - inputs: The currently pressed inputs.
  ///   - isFlying: Whether the player is creative mode flying or not.
  /// - Returns: The acceleration (before rotation).
  private func getInputAcceleration(_ inputs: Set<Input>, isFlying: Bool) -> SIMD3<Double> {
    let isSneaking = !isFlying && inputs.contains(.sneak)
    
    var velocityVector = SIMD3<Double>(0, 0, 0)
    
    if !(inputs.contains(.moveForward) && inputs.contains(.moveBackward)) {
      if inputs.contains(.moveForward) {
        velocityVector.z = 1
      } else if inputs.contains(.moveBackward) {
        velocityVector.z = -1
      }
    }
    
    if !(inputs.contains(.strafeLeft) && inputs.contains(.strafeRight)) {
      if inputs.contains(.strafeLeft) {
        velocityVector.x = 1
      } else if inputs.contains(.strafeRight) {
        velocityVector.x = -1
      }
    }
    
    if isFlying {
      if !(inputs.contains(.jump) && inputs.contains(.sneak)) {
        if inputs.contains(.jump) {
          velocityVector.y = 1
        } else if inputs.contains(.sneak) {
          velocityVector.y = -1
        }
      }
    }
    
    if isSneaking {
      velocityVector *= 0.3
    }
    
    return velocityVector
  }
}
 
