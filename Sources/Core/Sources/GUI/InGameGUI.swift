import SwiftCPUDetect
import CoreFoundation
import Collections

/// Never acquires nexus locks.
public class InGameGUI {
  // TODO: Figure out why anything greater than 252 breaks the protocol. Anything less than 256 should work afaict
  public static let maximumMessageLength = 252

  /// The number of seconds until messages should be hidden from the regular GUI.
  static let messageHideDelay: Double = 10
  /// The maximum number of messages displayed in the regular GUI.
  static let maximumDisplayedMessages = 10
  /// The width of the chat history.
  static let chatHistoryWidth = 330

  #if os(macOS)
  /// The system's CPU display name.
  static let cpuName = HWInfo.CPU.name()
  /// The system's CPU architecture.
  static let cpuArch = CpuArchitecture.current()?.rawValue
  /// The system's total memory.
  static let totalMem = (HWInfo.ramAmount() ?? 0) / (1024 * 1024 * 1024)
  /// A string containing information about the system's default GPU.
  static let gpuInfo = GPUDetection.mainMetalGPU()?.infoString()
  #endif

  static let xpLevelTextColor = Vec4f(126, 252, 31, 255) / 255
  static let debugScreenRowBackgroundColor = Vec4f(80, 80, 80, 144) / 255

  public init() {}

  /// Gets the GUI's content. Doesn't acquire any locks.
  public func content(game: Game, connection: ServerConnection?, state: GUIStateStorage) -> GUIElement {
    let (gamemode, inventory) = game.accessPlayer(acquireLock: false) { player in
      (player.gamemode.gamemode, player.inventory)
    }

    let inputState = game.accessInputState(acquireLock: false, action: identity)

    if state.showHUD {
      return GUIElement.stack {
        if gamemode != .spectator {
          GUIElement.stack {
            hotbarArea(game: game, gamemode: gamemode)

            GUIElement.sprite(.crossHair)
              .center()
          }
        }

        GUIElement.forEach(in: state.bossBars, spacing: 3) { bossBar in
          self.bossBar(bossBar)
        }
          .constraints(.top(2), .center)

        if state.movementAllowed && inputState.keys.contains(.tab) {
          tabList(game.tabList)
            .constraints(.top(8), .center)
        }

        if state.showDebugScreen {
          debugScreen(game: game, state: state)
        }

        chat(state: state)

        if state.showInventory {
          window(
            window: inventory.window,
            game: game,
            connection: connection,
            state: state
          )
        } else if let window = state.window {
          self.window(
            window: window,
            game: game,
            connection: connection,
            state: state
          )
        }
      }
    } else {
      return GUIElement.spacer(width: 0, height: 0)
    }
  }

  public func bossBar(_ bossBar: BossBar) -> GUIElement {
    let (background, foreground) = bossBar.color.sprites
    return GUIElement.list(spacing: 1) {
      GUIElement.message(bossBar.title, wrap: false)
        .constraints(.top(0), .center)

      GUIElement.stack {
        continuousMeter(bossBar.health, background: background, foreground: foreground)
        // TODO: Render both the background and foreground overlays separately (instead of assuming
        //   that they're both the same like they are in the vanilla resource pack)
        GUIElement.sprite(bossBar.style.overlay)
      }
    }
      .size(GUISprite.xpBarBackground.descriptor.size.x, nil)
  }

  public func tabList(_ tabList: TabList) -> GUIElement {
    // TODO: Resolve chat component content when building ui instead of when resolving it
    //   (just too tricky to do stuff without knowing the chat component's content)
    // TODO: Handle teams (changes sorting I think)
    // TODO: Spectator players should go first, then sort by display name (with no-display-name players
    //   coming first?) then sort by player name
    let sortedPlayers = tabList.players.values.sorted { left, right in
      // TODO: Sort by the name that's gonna be displayed (displayName ?? name),
      //   requires the above TODO to be resolved first
      left.name < right.name
    }

    let borderColor = Vec4f(0, 0, 0, 0.8)

    // TODO: Render borders between rows (harder than it sounds lol, will require more advanced layout
    //   controls in GUIElement).
    return GUIElement.list(direction: .horizontal, spacing: 0) {
      GUIElement.forEach(in: sortedPlayers, spacing: 0) { player in
        // TODO: Add text shadow when that's supported for chat components
        // TODO: Render spectator mode player names italic
        GUIElement.list(direction: .horizontal, spacing: 2) {
          if let displayName = player.displayName {
            GUIElement.message(displayName)
          } else {
            textWithShadow(player.name)
          }
        }
      }
        .padding(.bottom, -1)
        .background(Vec4f(0, 0, 0, 0.5))

      GUIElement.forEach(in: sortedPlayers, spacing: 1) { player in
        GUIElement.sprite(.playerConnectionStrength(player.connectionStrength))
          .padding([.top, .right], 1)
          .padding(.left, 2)
      }
        .background(Vec4f(0, 0, 0, 0.5))
    }
      .border([.top, .left, .bottom], 1, borderColor)
  }

  public func chat(state: GUIStateStorage) -> GUIElement {
    // TODO: Implement scrollable chat history.

    // Limit number of messages shown.
    let index = max(
      state.chat.messages.startIndex,
      state.chat.messages.endIndex - Self.maximumDisplayedMessages
    )
    let latestMessages = state.chat.messages[index..<state.chat.messages.endIndex]

    // If editing messages, only show messages sent/received within the last
    // `Self.messageHideDelay` seconds.
    let threshold = CFAbsoluteTimeGetCurrent() - Self.messageHideDelay
    var visibleMessages: Deque<ChatMessage>.SubSequence
    if state.showChat {
      visibleMessages = latestMessages
    } else {
      let lastVisibleIndex = latestMessages.lastIndex { message in
        message.timeReceived < threshold
      }?.advanced(by: 1) ?? latestMessages.startIndex
      visibleMessages = latestMessages[lastVisibleIndex..<latestMessages.endIndex]
    }

    return GUIElement.stack {
      if !visibleMessages.isEmpty {
        GUIElement.forEach(in: visibleMessages, spacing: 1) { message in
          // TODO: Chat message text shadows
          GUIElement.message(message.content, wrap: true)
        }
          .constraints(.top(0), .left(1))
          .padding(1)
          .size(Self.chatHistoryWidth, nil)
          .background(Vec4f(0, 0, 0, 0.5))
          .constraints(.bottom(40), .left(0))
      }

      if let messageInput = state.messageInput {
        textField(content: messageInput, cursorIndex: state.messageInputCursorIndex)
          .padding(2)
          .constraints(.bottom(0), .left(0))
      }
    }
  }

  public func textField(content: String, cursorIndex: String.Index) -> GUIElement {
    let messageBeforeCursor = String(content.prefix(upTo: cursorIndex))
    let messageAfterCursor = String(content.suffix(from: cursorIndex))

    return GUIElement.list(direction: .horizontal, spacing: 0) {
      textWithShadow(messageBeforeCursor)

      if Int(CFAbsoluteTimeGetCurrent() * 10/3) % 2 == 1 {
        if messageAfterCursor.isEmpty {
          textWithShadow("_")
            .positionInParent(messageBeforeCursor.isEmpty ? 0 : 1, 0)
        } else {
          GUIElement.spacer(width: 1, height: 11)
            .background(Vec4f(1, 1, 1, 1))
            .positionInParent(0, -1)
            .float()
        }
      }

      textWithShadow(messageAfterCursor)
    }
      .size(nil, Font.defaultCharacterHeight + 1)
      .expand(.horizontal)
      .padding([.top, .left, .right], 2)
      .padding(.bottom, 1)
      .background(Vec4f(0, 0, 0, 0.5))
  }

  /// Gets the contents of the hotbar (and nearby stats if in a gamemode with health).
  /// Doesn't acquire a nexus lock.
  public func hotbarArea(game: Game, gamemode: Gamemode) -> GUIElement {
    let (health, food, selectedSlot, xpBarProgress, xpLevel, hotbarSlots) =
      game.accessPlayer(acquireLock: false) { player in
        (
          player.health.health,
          player.nutrition.food,
          player.inventory.selectedHotbarSlot,
          player.experience.experienceBarProgress,
          player.experience.experienceLevel,
          player.inventory.hotbar
        )
      }

    return GUIElement.list(spacing: 0) {
      if gamemode.hasHealth {
        stats(health: health, food: food, xpBarProgress: xpBarProgress, xpLevel: xpLevel)
      }

      hotbar(slots: hotbarSlots, selectedSlot: selectedSlot)
    }
      .size(GUISprite.hotbar.descriptor.size.x + 2, nil)
      .constraints(.bottom(-1), .center)
  }

  public func hotbar(slots: [Slot], selectedSlot: Int) -> GUIElement {
    GUIElement.stack {
      GUIElement.sprite(.hotbar)
        .padding(1)
      GUIElement.sprite(.selectedHotbarSlot)
        .positionInParent(selectedSlot * 20, 0)

      GUIElement.forEach(in: slots, direction: .horizontal, spacing: 4) { slot in
        inventorySlot(slot)
      }
        .positionInParent(4, 4)
    }
  }

  public func window(
    window: Window,
    game: Game,
    connection: ServerConnection?,
    state: GUIStateStorage
  ) -> GUIElement {
    let mousePosition = game.accessInputState(acquireLock: false) { inputState in
      Vec2i(inputState.mousePosition / state.drawableScalingFactor)
    }

    return GUIElement.stack {
      GUIElement.spacer(width: 0, height: 0)
        .expand()
        .background(Vec4f(0, 0, 0, 0.702))
        .onClick {
          window.dropStackFromMouse(&state.mouseItemStack, connection: connection)
        }
        .onRightClick {
          window.dropItemFromMouse(&state.mouseItemStack, connection: connection)
        }

      GUIElement.stack {
        // Has a dummy click handler to prevent clicks within the inventory from propagating to the background
        window.type.background.onHoverKeyPress { event in
          return event.key == .leftMouseButton || event.key == .rightMouseButton
        }

        GUIElement.stack(elements: window.type.areas.map { area in
          windowArea(
            area,
            window,
            game: game,
            connection: connection,
            state: state
          )
        })
      }
        .center()

      if let mouseItemStack = state.mouseItemStack {
        inventorySlot(Slot(mouseItemStack))
          .positionInParent(mousePosition &- Vec2i(8, 8))
      }
    }
  }

  public func windowArea(
    _ area: WindowArea,
    _ window: Window,
    game: Game,
    connection: ServerConnection?,
    state: GUIStateStorage
  ) -> GUIElement {
    GUIElement.forEach(in: 0..<area.height, spacing: 2) { y in
      GUIElement.forEach(in: 0..<area.width, direction: .horizontal, spacing: 2) { x in
        let index = area.startIndex + y * area.width + x
        inventorySlot(window.slots[index])
          .onClick {
            window.leftClick(index, mouseStack: &state.mouseItemStack, connection: connection)
          }
          .onRightClick {
            window.rightClick(index, mouseStack: &state.mouseItemStack, connection: connection)
          }
          .onHoverKeyPress { event in
            let inputState = game.accessInputState(acquireLock: false, action: identity)
            return window.pressKey(
              over: index,
              event: event,
              mouseStack: &state.mouseItemStack,
              inputState: inputState,
              connection: connection
            )
          }
      }
    }
      .positionInParent(area.position)
  }

  public func inventorySlot(_ slot: Slot) -> GUIElement {
    // TODO: Make if blocks layout transparent (their children should be treated as children of the parent block)
    if let stack = slot.stack {
      return GUIElement.stack {
        GUIElement.item(id: stack.itemId)

        if stack.count != 1 {
          textWithShadow("\(stack.count)")
            .constraints(.bottom(-2), .right(-1))
            .float()
        }
      }
        .size(16, 16)
    } else {
      return GUIElement.spacer(width: 16, height: 16)
    }
  }

  public func textWithShadow(
    _ text: String,
    textColor: Vec4f = Vec4f(1, 1, 1, 1),
    shadowColor: Vec4f = Vec4f(62, 62, 62, 255) / 255
  ) -> GUIElement {
    if !text.isEmpty {
      return GUIElement.stack {
        GUIElement.text(text, color: shadowColor)
          .positionInParent(1, 1)
        GUIElement.text(text, color: textColor)
      }
    } else {
      return GUIElement.spacer(width: 0, height: 0)
    }
  }

  public enum ReadingDirection {
    case leftToRight
    case rightToLeft
  }

  public func stats(
    health: Float,
    food: Int,
    xpBarProgress: Float,
    xpLevel: Int
  ) -> GUIElement {
    GUIElement.list(spacing: 0) {
      GUIElement.stack {
        discreteMeter(
          Int(health.rounded()),
          fullIcon: .fullHeart,
          halfIcon: .halfHeart,
          outlineIcon: .heartOutline
        )

        discreteMeter(
          food,
          fullIcon: .fullFood,
          halfIcon: .halfFood,
          outlineIcon: .foodOutline,
          direction: .rightToLeft
        )
          .constraints(.top(0), .right(0))
      }
        .size(GUISprite.hotbar.descriptor.size.x, nil)
        .constraints(.top(0), .center)

      GUIElement.stack {
        continuousMeter(
          xpBarProgress,
          background: .xpBarBackground,
          foreground: .xpBarForeground
        )
          .constraints(.top(0), .center)

        outlinedText("\(xpLevel)", textColor: Self.xpLevelTextColor)
          .constraints(.top(-7), .center)
      }
        .padding(1)
        .constraints(.top(0), .center)
    }
  }

  /// Gets the contents of the debug screen, doesn't acquire a nexus lock.
  public func debugScreen(game: Game, state: GUIStateStorage) -> GUIElement {
    var blockPosition = BlockPosition(x: 0, y: 0, z: 0)
    var chunkSectionPosition = ChunkSectionPosition(sectionX: 0, sectionY: 0, sectionZ: 0)
    var position: Vec3d = .zero
    var pitch: Float = 0
    var yaw: Float = 0
    var heading: Direction = .north
    var gamemode: Gamemode = .adventure
    game.accessPlayer(acquireLock: false) { player in
      position = player.position.vector
      blockPosition = player.position.blockUnderneath
      chunkSectionPosition = player.position.chunkSection
      pitch = MathUtil.degrees(from: player.rotation.pitch)
      yaw = MathUtil.degrees(from: player.rotation.yaw)
      heading = player.rotation.heading
      gamemode = player.gamemode.gamemode
    }
    blockPosition.y += 1

    let x = String(format: "%.06f", position.x).prefix(7)
    let y = String(format: "%.06f", position.y).prefix(7)
    let z = String(format: "%.06f", position.z).prefix(7)

    let relativePosition = blockPosition.relativeToChunkSection
    let relativePositionString = "\(relativePosition.x) \(relativePosition.y) \(relativePosition.z)"
    let chunkSectionString = "\(chunkSectionPosition.sectionX) \(chunkSectionPosition.sectionY) \(chunkSectionPosition.sectionZ)"

    let yawString = String(format: "%.01f", yaw)
    let pitchString = String(format: "%.01f", pitch)
    let axisHeading = "\(heading.isPositive ? "positive" : "negative") \(heading.axis)"

    var lightPosition = blockPosition
    lightPosition.y += 1
    let skyLightLevel = game.world.getSkyLightLevel(at: lightPosition)
    let blockLightLevel = game.world.getBlockLightLevel(at: lightPosition)

    let biome = game.world.getBiome(at: blockPosition)

    let leftSections: [[String]] = [
      [
        "Minecraft \(Constants.versionString) (Delta Client)",
        renderStatisticsString(state.inner.debouncedRenderStatistics()),
        "Dimension: \(game.world.dimension.identifier)",
      ],
      [
        "XYZ: \(x) / \(y) / \(z)",
        // Block under feet
        "Block: \(blockPosition.x) \(blockPosition.y) \(blockPosition.z)",
        "Chunk: \(relativePositionString) in \(chunkSectionString)",
        "Facing: \(heading) (Towards \(axisHeading)) (\(yawString) / \(pitchString))",
        // Lighting (at foot level)
        "Light: \(skyLightLevel) sky, \(blockLightLevel) block",
        "Biome: \(biome?.identifier.description ?? "not loaded")",
        "Gamemode: \(gamemode.string)"
      ]
    ]

    #if os(macOS)
      let rightSections: [[String]] = [
        [
          "CPU: \(Self.cpuName ?? "unknown") (\(Self.cpuArch ?? "n/a"))",
          "Total mem: \(Self.totalMem)GB",
          "GPU: \(Self.gpuInfo ?? "unknown")"
        ]
      ]
    #else
      let rightSections: [[String]] = []
    #endif

    return GUIElement.stack {
      debugScreenList(leftSections, side: .left)
      debugScreenList(rightSections, side: .right)
    }
  }

  public enum Alignment {
    case left
    case right
  }

  public func debugScreenList(_ sections: [[String]], side: Alignment) -> GUIElement {
    GUIElement.forEach(in: sections, spacing: 6) { section in
      GUIElement.forEach(in: section, spacing: 0) { line in
        GUIElement.text(line)
          .padding([.left, .top], 1)
          .padding([.right], 2)
          .background(Self.debugScreenRowBackgroundColor)
          .constraints(.top(0), side == .left ? .left(0) : .right(0))
      }
        .padding(1)
    }
  }

  /// Converts the given render statistics into the format required by the debug screen;
  ///
  /// ```
  /// XX fps (XX.XX theoretical) (XX.XXms cpu, XX.XXms gpu)
  /// ```
  ///
  /// Theoretical FPS and GPU time are only included if being collected.
  public func renderStatisticsString(_ renderStatistics: RenderStatistics) -> String {
    let theoreticalFPSString = renderStatistics.averageTheoreticalFPS.map { theoreticalFPS in
      "(\(theoreticalFPS) theoretical)"
    }
    let gpuTimeString = renderStatistics.averageGPUTime.map { gpuTime in
      String(format: "%.02fms gpu", gpuTime * 1000)
    }
    let cpuTimeString = String(format: "%.02fms cpu", renderStatistics.averageCPUTime * 1000)
    let fpsString = String(format: "%.00f fps", renderStatistics.averageFPS)

    let timingsString = [cpuTimeString, gpuTimeString].compactMap(identity).joined(separator: ", ")
    
    return [fpsString, theoreticalFPSString, "(\(timingsString))"].compactMap(identity).joined(separator: " ")
  }

  public func outlinedText(
    _ text: String,
    textColor: Vec4f,
    outlineColor: Vec4f = Vec4f(0, 0, 0, 1)
  ) -> GUIElement {
    let outlineText = GUIElement.text(text, color: outlineColor)
    return GUIElement.stack {
      outlineText.constraints(.top(0), .left(1))
      outlineText.constraints(.top(1), .left(0))
      outlineText.constraints(.top(1), .left(2))
      outlineText.constraints(.top(2), .left(1))
      GUIElement.text(text, color: textColor)
        .constraints(.top(1), .left(1))
    }
  }

  public func discreteMeter(
    _ value: Int,
    fullIcon: GUISprite,
    halfIcon: GUISprite,
    outlineIcon: GUISprite,
    direction: ReadingDirection = .leftToRight
  ) -> GUIElement {
    let fullIconCount = value / 2
    let hasHalfIcon = value % 2 == 0
    var range = Array(0..<10)
    if direction == .rightToLeft {
      range = range.reversed()
    }
    return GUIElement.forEach(in: range, direction: .horizontal, spacing: -1) { i in
      GUIElement.stack {
        GUIElement.sprite(outlineIcon)
        if i < fullIconCount {
          GUIElement.sprite(fullIcon)
        } else if hasHalfIcon && i == fullIconCount {
          GUIElement.sprite(halfIcon)
        }
      }
    }
  }

  public func continuousMeter(
    _ value: Float,
    background: GUISprite,
    foreground:GUISprite
  ) -> GUIElement {
    var croppedForeground = foreground.descriptor
    croppedForeground.size.x = Int(Float(croppedForeground.size.x) * value)
    return GUIElement.stack {
      GUIElement.sprite(background)
      GUIElement.customSprite(croppedForeground)
    }
  }
}
