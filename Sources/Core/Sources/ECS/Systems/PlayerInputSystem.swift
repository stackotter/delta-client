import FirebladeECS

public struct PlayerInputSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityRotation.self,
      EntityCamera.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (rotation, camera, _) = family.next() else {
      log.error("PlayerInputSystem failed to get player to tick")
      return
    }
    
    let inputState = nexus.single(InputState.self).component
    
    updateRotation(inputState, rotation)
    updateCamera(inputState, camera)
    
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
}

