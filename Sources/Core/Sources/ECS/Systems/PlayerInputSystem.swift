import FirebladeECS

public struct PlayerInputSystem: System {
  var connection: ServerConnection?

  public init(_ connection: ServerConnection?) {
    self.connection = connection
  }

  public func update(_ nexus: Nexus, _ world: World) throws {
    var family = nexus.family(
      requiresAll: EntityRotation.self,
      PlayerInventory.self,
      EntityCamera.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (rotation, inventory, camera, _) = family.next() else {
      log.error("PlayerInputSystem failed to get player to tick")
      return
    }

    let inputState = nexus.single(InputState.self).component
    let guiState = nexus.single(GUIStateStorage.self).component

    if guiState.messageInput != nil {
      inputState.inputs = []
      inputState.newlyReleased = []
      inputState.newlyPressed = []
    }

    // Handle non-movement inputs
    for input in inputState.newlyPressed {
      switch input {
        case .changePerspective:
          camera.cyclePerspective()
        case .toggleDebugHUD:
          guiState.showDebugScreen = !guiState.showDebugScreen
        case .slot1:
          inventory.selectedHotbarSlot = 0
        case .slot2:
          inventory.selectedHotbarSlot = 1
        case .slot3:
          inventory.selectedHotbarSlot = 2
        case .slot4:
          inventory.selectedHotbarSlot = 3
        case .slot5:
          inventory.selectedHotbarSlot = 4
        case .slot6:
          inventory.selectedHotbarSlot = 5
        case .slot7:
          inventory.selectedHotbarSlot = 6
        case .slot8:
          inventory.selectedHotbarSlot = 7
        case .slot9:
          inventory.selectedHotbarSlot = 8
        case .nextSlot:
          inventory.selectedHotbarSlot = (inventory.selectedHotbarSlot + 1) % 9
        case .previousSlot:
          inventory.selectedHotbarSlot = (inventory.selectedHotbarSlot + 8) % 9
        default:
          break
      }
    }

    if var message = guiState.messageInput {
      if inputState.newlyPressedCharacters.contains("\r") {
        try connection?.sendPacket(ChatMessageServerboundPacket(message: message))
        guiState.messageInput = nil
      } else {
        message += inputState.newlyPressedCharacters
        guiState.messageInput = message
      }
    } else if inputState.newlyPressed.contains(.openChat) {
      guiState.messageInput = ""
    }

    // Handle mouse input
    updateRotation(inputState, rotation)

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
}
