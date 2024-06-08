import FirebladeECS

#if os(macOS)
  // Used to access clipboard
  import AppKit
#endif

/// Handles all player input except for input related to player movement (see ``PlayerAccelerationSystem``).
public final class PlayerInputSystem: System {
  var connection: ServerConnection?
  weak var game: Game?
  var eventBus: EventBus
  let configuration: ClientConfiguration
  let font: Font
  let locale: MinecraftLocale

  public init(
    _ connection: ServerConnection?,
    _ game: Game,
    _ eventBus: EventBus,
    _ configuration: ClientConfiguration,
    _ font: Font,
    _ locale: MinecraftLocale
  ) {
    self.connection = connection
    self.game = game
    self.eventBus = eventBus
    self.configuration = configuration
    self.font = font
    self.locale = locale
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
      EntitySneaking.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (rotation, inventory, camera, gamemode, sneaking, _) = family.next() else {
      log.error("PlayerInputSystem failed to get player to tick")
      return
    }

    let inputState = nexus.single(InputState.self).component
    let guiState = nexus.single(GUIStateStorage.self).component

    let mousePosition = Vec2i(inputState.mousePosition / guiState.drawableScalingFactor)

    // Handle non-movement inputs
    var isInputSuppressed: [Bool] = []
    for event in inputState.newlyPressed {
      var suppressInput = false

      // TODO: Formalize 'mouse targeted interactions are allowed', seems a bit hacky this way
      if !suppressInput && !guiState.movementAllowed {
        // Recompute the gui everytime that we get it to handle a new interaction because e.g. if previous
        // interactions within the same tick have closed the inventory and opened the chat, then the old
        // gui would still be handling the input for the inventory. That's a bit contrived, but I'm sure
        // other edge cases are possible, and recomputing the GUI is relatively cheap (and multiple inputs
        // within a single tick should be uncommon anyway).

        // Be careful not to acquire a nexus lock here (passing the guiState parameter ensures this)
        let gui = game.compileGUI(
          withFont: font,
          locale: locale,
          connection: connection,
          guiState: guiState
        )
        suppressInput = gui.handleInteraction(.press(event), at: mousePosition)
      }

      if !suppressInput {
        suppressInput = try handleChat(event, inputState, guiState)
      }

      if !suppressInput {
        suppressInput = try handleInventory(event, inventory, guiState, eventBus, connection)
      }

      if !suppressInput {
        suppressInput = try handleWindow(event, guiState, eventBus, connection)
      }

      if !suppressInput {
        switch event.input {
          case .changePerspective:
            camera.cyclePerspective()
          case .toggleHUD:
            guiState.showHUD = !guiState.showHUD
          case .toggleDebugHUD:
            guiState.showDebugScreen = !guiState.showDebugScreen
          case .toggleInventory:
            // Closing the inventory is handled by `handleInventory`
            guiState.showInventory = true
            inputState.releaseAll()
            eventBus.dispatch(ReleaseCursorEvent())
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
          case .dropItem:
            // TODO: Implement a similar check on other desktop platforms (Linux, Windows)
            #if os(macOS)
              let isQuitKeyboardShortcut =
                event.key == .q
                && (inputState.keys.contains(where: \.isCommand)
                  || inputState.newlyPressed.contains { $0.key?.isCommand == true })
              guard !isQuitKeyboardShortcut else {
                break
              }
            #endif

            let slotIndex = PlayerInventory.hotbarArea.startIndex + inventory.selectedHotbarSlot
            inventory.window.dropItemFromSlot(
              slotIndex,
              mouseItemStack: nil,
              connection: connection
            )
          case .place:
            // Block breaking is handled by ``PlayerBlockBreakingSystem``, this just handles hand animation and
            // other non breaking things for the `.destroy` input (e.g. attacking)
            if inventory.hotbar[inventory.selectedHotbarSlot].stack != nil {
              try connection?.sendPacket(UseItemPacket(hand: .mainHand))
            }

            guard let targetedThing = game.targetedThing(acquireLock: false) else {
              break
            }

            switch targetedThing.target {
              case let .block(blockPosition):
                let cursor = targetedThing.cursor
                try connection?.sendPacket(
                  PlayerBlockPlacementPacket(
                    hand: .mainHand,
                    location: blockPosition,
                    face: targetedThing.face,
                    cursorPositionX: cursor.x,
                    cursorPositionY: cursor.y,
                    cursorPositionZ: cursor.z,
                    insideBlock: targetedThing.distance < 0
                  )
                )

                if gamemode.gamemode.canPlaceBlocks {
                  // TODO: Predict the result of block placement so that we're not relying on the server
                  //   (quite noticeable latency)
                }
              case let .entity(entityId):
                let targetedPosition = targetedThing.targetedPosition
                try connection?.sendPacket(
                  InteractEntityPacket(
                    entityId: Int32(entityId),
                    interaction: .interactAt(
                      targetX: targetedPosition.x,
                      targetY: targetedPosition.y,
                      targetZ: targetedPosition.z,
                      hand: .mainHand,
                      isSneaking: sneaking.isSneaking
                    )
                  )
                )
                try connection?.sendPacket(
                  InteractEntityPacket(
                    entityId: Int32(entityId),
                    interaction: .interact(hand: .mainHand, isSneaking: sneaking.isSneaking)
                  )
                )
            }
          case .destroy:
            guard let targetedEntity = game.targetedEntity(acquireLock: false) else {
              try connection?.sendPacket(AnimationServerboundPacket(hand: .mainHand))
              break
            }

            var entityId = targetedEntity.target
            if let dragonParts = game.accessComponent(
              entityId: targetedEntity.target,
              EnderDragonParts.self,
              acquireLock: false,
              action: identity
            ) {
              guard
                let dragonPosition = game.accessComponent(
                  entityId: targetedEntity.target,
                  EntityPosition.self,
                  acquireLock: false,
                  action: identity
                )
              else {
                log.warning("Ender dragon missing position")
                break
              }

              let ray = game.accessPlayer(acquireLock: false, action: \.ray)
              var currentDistance: Float = Player.attackReach
              for part in dragonParts.parts {
                let aabb = part.aabb(withParentPosition: dragonPosition.vector)
                if let (distance, _) = aabb.intersectionDistanceAndFace(with: ray),
                  distance < currentDistance
                {
                  entityId = targetedEntity.target + part.entityIdOffset
                  currentDistance = distance
                }
              }

              print(entityId, targetedEntity.target)
              print(currentDistance)
            }

            try connection?.sendPacket(
              InteractEntityPacket(
                entityId: Int32(entityId),
                interaction: .attack(isSneaking: sneaking.isSneaking)
              )
            )
          default:
            break
        }

        if event.key == .escape {
          eventBus.dispatch(OpenInGameMenuEvent())
        }
      }

      isInputSuppressed.append(suppressInput)
    }

    // Handle mouse input.
    if guiState.movementAllowed {
      updateRotation(inputState, rotation)
    }

    inputState.resetMouseDelta()
    inputState.tick(isInputSuppressed, eventBus, configuration)
  }

  /// - Returns: Whether to suppress the input associated with the event or not. `true` while user is typing.
  private func handleChat(
    _ event: KeyPressEvent,
    _ inputState: InputState,
    _ guiState: GUIStateStorage
  ) throws -> Bool {
    if var message = guiState.messageInput {
      var newCharacters: [Character] = []
      if event.key == .enter {
        if !message.isEmpty {
          try connection?.sendPacket(ChatMessageServerboundPacket(message))
          guiState.playerMessageHistory.append(message)
          guiState.currentMessageIndex = nil
        }
        guiState.messageInput = nil
        eventBus.dispatch(CaptureCursorEvent())
        return true
      } else if event.key == .escape {
        guiState.messageInputCursor = 0
        guiState.messageInput = nil
        guiState.currentMessageIndex = nil
        eventBus.dispatch(CaptureCursorEvent())
        return true
      } else if event.key == .delete {
        if !message.isEmpty && guiState.messageInputCursor < guiState.messageInput?.count ?? 0 {
          guiState.messageInput?.remove(at: message.index(before: guiState.messageInputCursorIndex))
        }
      } else if event.key == .upArrow {
        // If no message is selected, select the above message
        if let index = guiState.currentMessageIndex, index > 0 {
          guiState.currentMessageIndex = index - 1
          guiState.messageInput = guiState.playerMessageHistory[index - 1]
        } else if guiState.currentMessageIndex == nil && !guiState.playerMessageHistory.isEmpty {
          guiState.stashedMessageInput = guiState.messageInput
          let index = guiState.playerMessageHistory.count - 1
          guiState.currentMessageIndex = index
          guiState.messageInput = guiState.playerMessageHistory[index]
        }
      } else if event.key == .downArrow {
        // If there is a message selected, index down a message
        if let index = guiState.currentMessageIndex {
          if index < guiState.playerMessageHistory.count - 1 {
            guiState.currentMessageIndex = index + 1
            guiState.messageInput = guiState.playerMessageHistory[index + 1]
          } else {
            // If there is no message to index down to, go back to what the user was typing originally
            guiState.currentMessageIndex = nil
            guiState.messageInput = guiState.stashedMessageInput ?? ""
          }
        }
      } else if event.key == .leftArrow
        && guiState.messageInput?.count ?? 0 > guiState.messageInputCursor
      {
        guiState.messageInputCursor += 1
      } else if event.key == .rightArrow && guiState.messageInputCursor > 0 {
        guiState.messageInputCursor -= 1
      } else {
        #if os(macOS)
          if event.key == .v
            && !inputState.keys.intersection([.leftCommand, .rightCommand]).isEmpty
          {
            // Handle paste keyboard shortcut
            if let content = NSPasteboard.general.string(forType: .string) {
              newCharacters = Array(content)
            }
          } else if message.utf8.count < InGameGUI.maximumMessageLength {
            newCharacters = event.characters
          }
        #else
          if message.utf8.count < InGameGUI.maximumMessageLength {
            newCharacters = event.characters
          }
        #endif

        // Ensure that the message doesn't exceed 256 bytes (including if multi-byte characters are entered).
        var count = 0
        for character in newCharacters {
          guard character.isPrintable, character != "\t" else {
            // TODO: Make this check less restrictive, it's currently over-cautious
            continue
          }
          guard character.utf8.count + message.utf8.count <= InGameGUI.maximumMessageLength else {
            break
          }

          let index = message.index(guiState.messageInputCursorIndex, offsetBy: count)
          message.insert(character, at: index)
          count += 1
        }
        guiState.messageInput = message
      }
    } else if event.input == .openChat {
      guiState.messageInput = ""
      // TODO: Refactor input handling to be a bit more declarative so that something like
      //   issue #192 is less likely to happen again. Besides, this input handling code is
      //   pretty spaghetti and could do with a makeover anyway.
      inputState.releaseAll()
      eventBus.dispatch(ReleaseCursorEvent())
    } else if event.key == .forwardSlash {
      guiState.messageInput = "/"
      inputState.releaseAll()
      eventBus.dispatch(ReleaseCursorEvent())
    }

    // Suppress inputs while the user is typing.
    return guiState.showChat
  }

  /// - Returns: Whether to suppress the input associated with the event or not.
  private func handleInventory(
    _ event: KeyPressEvent,
    _ inventory: PlayerInventory,
    _ guiState: GUIStateStorage,
    _ eventBus: EventBus,
    _ connection: ServerConnection?
  ) throws -> Bool {
    guard guiState.showInventory else {
      return false
    }

    if event.key == .escape || event.input == .toggleInventory {
      // Weirdly enough, the vanilla client sends a close window packet when closing the player's
      // inventory even though it never tells the server that it opened the inventory in the first
      // place. Likely just for the server to verify the slots and chuck out anything in the crafting
      // area.
      try inventory.window.close(
        mouseStack: &guiState.mouseItemStack,
        eventBus: eventBus,
        connection: connection
      )
      guiState.showInventory = false
    }

    return true
  }

  /// - Returns: Whether to suppress the input associated with the event or not.
  private func handleWindow(
    _ event: KeyPressEvent,
    _ guiState: GUIStateStorage,
    _ eventBus: EventBus,
    _ connection: ServerConnection?
  ) throws -> Bool {
    guard let window = guiState.window else {
      return false
    }

    if event.key == .escape || event.input == .toggleInventory {
      try window.close(
        mouseStack: &guiState.mouseItemStack,
        eventBus: eventBus,
        connection: connection
      )
      guiState.window = nil
    }

    return true
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
