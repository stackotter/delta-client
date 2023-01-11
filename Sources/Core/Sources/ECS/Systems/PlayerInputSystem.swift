import FirebladeECS

#if os(macOS)
import AppKit // Used to access clipboard
#endif

public final class PlayerInputSystem: System {
  var connection: ServerConnection?
  weak var game: Game?
  var eventBus: EventBus

  public init(_ connection: ServerConnection?, _ game: Game, _ eventBus: EventBus) {
    self.connection = connection
    self.game = game
    self.eventBus = eventBus
  }

  public func update(_ nexus: Nexus, _ world: World) throws {
    guard let game = game else {
      return
    }

    var family = nexus.family(
      requiresAll: EntityRotation.self,
      PlayerInventory.self,
      EntityCamera.self,
      PlayerGamemode.self,
      PlayerAttributes.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (rotation, inventory, camera, gamemode, attributes, _) = family.next() else {
      log.error("PlayerInputSystem failed to get player to tick")
      return
    }

    let inputState = nexus.single(InputState.self).component
    let guiState = nexus.single(GUIStateStorage.self).component

    // Handle non-movement inputs
    var isInputSuppressed: [Bool] = []
    for event in inputState.newlyPressed {
      let suppressInput = try handleChat(event, inputState, guiState)

      if !suppressInput {
        switch event.input {
          case .changePerspective:
            camera.cyclePerspective()
          case .toggleDebugHUD:
            guiState.showDebugScreen = !guiState.showDebugScreen
          case .toggleInventory:
            guiState.showInventory = !guiState.showInventory
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
          case .place, .destroy:
            if inventory.hotbar[inventory.selectedHotbarSlot].stack != nil {
              try connection?.sendPacket(UseItemPacket(hand: .mainHand))
            } else {
              try connection?.sendPacket(AnimationServerboundPacket(hand: .mainHand))
            }

            if event.input == .place && gamemode.gamemode != .spectator {
              guard let (position, cursor, face, distance) = game.targetedBlock(acquireLock: false) else {
                break
              }

              try connection?.sendPacket(PlayerBlockPlacementPacket(
                hand: .mainHand,
                location: position,
                face: face,
                cursorPositionX: cursor.x,
                cursorPositionY: cursor.y,
                cursorPositionZ: cursor.z,
                insideBlock: distance < 0
              ))
            } else if event.input == .destroy && attributes.canInstantBreak {
              guard let (position, _, face, _) = game.targetedBlock(acquireLock: false) else {
                break
              }

              try connection?.sendPacket(PlayerDiggingPacket(
                status: .startedDigging,
                location: position,
                face: face
              ))
            }
          default:
            break
        }

        if event.key == .escape {
          eventBus.dispatch(OpenInGameMenuEvent())
        }
      }

      isInputSuppressed.append(suppressInput)
    }

    // Handle mouse input
    if !guiState.isChatOpen {
      updateRotation(inputState, rotation)
    }

    inputState.resetMouseDelta()
    inputState.tick(isInputSuppressed, eventBus)
  }

  /// - Returns: Whether to suppress the input associated with the event or not. `true` while user is typing.
  private func handleChat(_ event: KeyPressEvent, _ inputState: InputState, _ guiState: GUIStateStorage) throws -> Bool {
    if var message = guiState.messageInput {
      var newCharacters: [Character] = []
      if event.key == .enter {
        if !message.isEmpty {
          try connection?.sendPacket(ChatMessageServerboundPacket(message))
        }
        guiState.messageInput = nil
        return true
      } else if event.key == .escape {
        guiState.messageInput = nil
        return true
      } else if event.key == .delete {
        if !message.isEmpty {
          guiState.messageInput?.removeLast()
        }
      } else {
        #if os(macOS)
        if event.key == .v && !inputState.keys.intersection([.leftCommand, .rightCommand]).isEmpty {
          // Handle paste keyboard shortcut
          if let content = NSPasteboard.general.string(forType: .string) {
            newCharacters = Array(content)
          }
        } else if message.utf8.count < GUIState.maximumMessageLength {
          newCharacters = event.characters
        }
        #else
        if message.utf8.count < GUIState.maximumMessageLength {
          newCharacters = event.characters
        }
        #endif

        // Ensure that the message doesn't exceed 256 bytes (including if multi-byte characters are entered).
        for character in newCharacters {
          guard character.isASCII, character != "\t" else {
            // TODO: Make this check less restrictive, it's currently over-cautious
            continue
          }
          guard character.utf8.count + message.utf8.count <= GUIState.maximumMessageLength else {
            break
          }
          message.append(character)
        }
        guiState.messageInput = message
      }
    } else if event.input == .openChat {
      guiState.messageInput = ""
    } else if event.key == .forwardSlash {
      guiState.messageInput = "/"
    }

    // Supress inputs while the user is typing
    return guiState.isChatOpen
  }

  /// Updates the direction which the player is looking.
  /// - Parameters:
  ///   - inputState: The current input state.
  ///   - rotation: The player's rotation component.
  private func updateRotation(_ inputState: InputState, _ rotation: EntityRotation) {
    let thumbstickSensitivity: Float = 0.2
    let stick = inputState.rightThumbstick * thumbstickSensitivity

    let mouseDelta = inputState.mouseDelta
    var yaw = rotation.yaw + mouseDelta.x + stick.x
    var pitch = rotation.pitch + mouseDelta.y - stick.y

    // Clamp pitch between -90 and 90
    pitch = MathUtil.clamp(pitch, -.pi / 2, .pi / 2)

    // Wrap yaw to be between 0 and 360
    let remainder = yaw.truncatingRemainder(dividingBy: .pi * 2)
    yaw = remainder < 0 ? .pi * 2 + remainder : remainder

    rotation.yaw = yaw
    rotation.pitch = pitch
  }
}
