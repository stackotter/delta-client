import Metal
import Collections
import FirebladeMath
import DeltaCore
import SwiftCPUDetect

struct GUI {
  /// The number of seconds until messages should be hidden from the regular GUI.
  static let messageHideDelay: Double = 10
  /// The maximum number of messages displayed in the regular GUI.
  static let maximumDisplayedMessages = 10
  /// The width of the chat history.
  static let chatHistoryWidth = 330
  /// The width of indent to use when wrapping chat messages.
  static let chatWrapIndent = 4

  /// The system's CPU display name.
  static let cpuName = HWInfo.CPU.name()
  /// The system's CPU architecture.
  static let cpuArch = CpuArchitecture.current()?.rawValue
  /// The system's total memory.
  static let totalMem = (HWInfo.ramAmount() ?? 0) / (1024 * 1024 * 1024)
  /// A string containing information about the system's default GPU.
  static let gpuInfo = GPUDetection.mainMetalGPU()?.infoString()

  var client: Client
  var renderStatistics = RenderStatistics(gpuCountersEnabled: false)
  var fpsUpdateInterval = 0.4
  var lastFPSUpdate: CFAbsoluteTime = 0
  var savedRenderStatistics = RenderStatistics(gpuCountersEnabled: false)
  var context: GUIContext
  var profiler: Profiler<RenderingMeasurement>

  init(
    client: Client,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.client = client
    self.profiler = profiler

    let resources = client.resourcePack.vanillaResources
    let font = resources.fontPalette.defaultFont
    let fontArrayTexture = try font.createArrayTexture(
      device: device,
      commandQueue: commandQueue
    )
    fontArrayTexture.label = "fontArrayTexture"

    let guiTexturePalette = try GUITexturePalette(resources.guiTexturePalette)
    let guiArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.guiTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    guiArrayTexture.label = "guiArrayTexture"

    let itemTexturePalette = resources.itemTexturePalette
    let itemArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.itemTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    itemArrayTexture.label = "itemArrayTexture"

    let blockTexturePalette = resources.blockTexturePalette
    let blockArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.blockTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    blockArrayTexture.label = "blockArrayTexture"

    context = GUIContext(
      font: font,
      fontArrayTexture: fontArrayTexture,
      guiTexturePalette: guiTexturePalette,
      guiArrayTexture: guiArrayTexture,
      itemTexturePalette: itemTexturePalette,
      itemArrayTexture: itemArrayTexture,
      itemModelPalette: resources.itemModelPalette,
      blockArrayTexture: blockArrayTexture,
      blockModelPalette: resources.blockModelPalette,
      blockTexturePalette: blockTexturePalette
    )
  }

  mutating func update(_ screenSize: Vec2i) -> GUIGroupElement {
    let state = client.game.guiState()
    var root = GUIGroupElement(screenSize)

    guard state.showHUD else {
      return root
    }

    // TODO: Crosshair should be visible in spectator mode when able to interact with an entity
    if client.game.currentGamemode() != .spectator {
      // Hot bar area (hot bar, health, food, etc.)
      hotbarArea(&root)

      // Render crosshair
      root.add(GUISprite.crossHair, .center)
    }

    // Debug screen
    if state.showDebugScreen {
      debugScreen(&root)
    }

    // Chat
    chat(&root, state.chat.messages, state.messageInput, state.messageInputCursorIndex, screenSize)

    return root
  }

  func chat(
    _ parentGroup: inout GUIGroupElement,
    _ messages: Deque<ChatMessage>,
    _ messageInput: String?,
    _ messageInputCursorIndex: String.Index,
    _ screenSize: Vec2i
  ) {
    let chatIsOpen = messageInput != nil

    let font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    let builder = TextMeshBuilder(font: font)
    let threshold = CFAbsoluteTimeGetCurrent() - Self.messageHideDelay
    var chatLines: [(text: String, indent: Bool)] = []
    for message in messages.reversed() {
      if !chatIsOpen && message.timeReceived < threshold {
        break
      }

      let text = message.content.toText(with: client.resourcePack.getDefaultLocale())
      let wrappedLines: [String]
      wrappedLines = builder.wrap(
        text,
        maximumWidth: Self.chatHistoryWidth - 2,
        indent: Self.chatWrapIndent
      )

      var done = false
      for (i, line) in wrappedLines.enumerated().reversed() {
        if chatLines.count >= Self.maximumDisplayedMessages {
          done = true
          break
        }

        chatLines.append((text: line, indent: i != 0))
      }

      if done {
        break
      }
    }

    if !chatLines.isEmpty {
      var chat = GUIList(rowHeight: 9)

      for (chatLine, indent) in chatLines.reversed() {
        if indent {
          var group = GUIGroupElement([Self.chatHistoryWidth - 1, chat.rowHeight])
          group.add(chatLine, .top(0), .left(Self.chatWrapIndent))
          chat.add(group)
        } else {
          chat.add(chatLine)
        }
      }

      parentGroup.add(GUIRectangle(
        size: [Self.chatHistoryWidth, chatLines.count * chat.rowHeight],
        color: [0, 0, 0, 0.5]
      ), .bottom(40), .left(0))

      parentGroup.add(
        chat,
        .bottom(40),
        .left(2)
      )
    }

    if let messageInput = messageInput {
      parentGroup.add(GUITextInput(
        content: messageInput,
        width: screenSize.x - 4,
        cursorIndex: messageInputCursorIndex
      ), .bottom(2), .left(2))
    }
  }

  func hotbarArea(_ parentGroup: inout GUIGroupElement) {
    var group = GUIGroupElement([184, 40])
    var gamemode: Gamemode = .adventure
    var health: Float = 0
    var food: Int = 0
    var selectedSlot: Int = 0
    var xpBarProgress: Float = 0
    var xpLevel: Int = 0
    var hotbarSlots: [Slot] = []
    client.game.accessPlayer { player in
      gamemode = player.gamemode.gamemode
      health = player.health.health
      food = player.nutrition.food
      selectedSlot = player.inventory.selectedHotbarSlot
      xpBarProgress = player.experience.experienceBarProgress
      xpLevel = player.experience.experienceLevel
      hotbarSlots = player.inventory.hotbar
    }

    stats(
      &group,
      gamemode: gamemode,
      health: health,
      food: food,
      xpBarProgress: xpBarProgress,
      xpLevel: xpLevel
    )
    hotbar(&group, selectedSlot: selectedSlot, slots: hotbarSlots)

    parentGroup.add(group, .bottom(-1), .center)
  }

  func hotbar(_ group: inout GUIGroupElement, selectedSlot: Int, slots: [Slot]) {
    group.add(GUISprite.hotbar, .bottom(1), .center)
    group.add(GUISprite.selectedHotbarSlot, .bottom(0), .left(20 * selectedSlot))

    for (i, slot) in slots.enumerated() {
      if let stack = slot.stack {
        group.add(GUIInventoryItem(itemId: stack.itemId), .bottom(4), .left(20 * i + 4))

        // Item count
        if stack.count != 1 {
          let offset = 20 * (8 - i) + 4
          group.add(GUIColoredString(String(stack.count), [62, 62, 62, 255] / 255), .bottom(2), .right(offset - 1))
          group.add(String(stack.count), .bottom(3), .right(offset))
        }
      }
    }
  }

  func stats(
    _ group: inout GUIGroupElement,
    gamemode: Gamemode,
    health: Float,
    food: Int,
    xpBarProgress: Float,
    xpLevel: Int
  ) {
    if gamemode.hasHealth {
      // Health
      group.add(
        GUIStatBar(
          value: Int(health.rounded()),
          fullIcon: .fullHeart,
          halfIcon: .halfHeart,
          outlineIcon: .heartOutline
        ),
        .top(0),
        .left(1)
      )

      // Hunger
      group.add(
        GUIStatBar(
          value: food,
          fullIcon: .fullFood,
          halfIcon: .halfFood,
          outlineIcon: .foodOutline,
          reversed: true
        ),
        .top(0),
        .right(1)
      )

      // XP bar
      group.add(
        GUIXPBar(level: xpLevel, progress: xpBarProgress),
        .top(4),
        .center
      )
    }
  }

  mutating func debugScreen(_ root: inout GUIGroupElement) {
    // Fetch relevant player properties
    var blockPosition = BlockPosition(x: 0, y: 0, z: 0)
    var chunkSectionPosition = ChunkSectionPosition(sectionX: 0, sectionY: 0, sectionZ: 0)
    var position: Vec3d = .zero
    var pitch: Float = 0
    var yaw: Float = 0
    var heading: Direction = .north
    var gamemode: Gamemode = .adventure
    client.game.accessPlayer { player in
      position = player.position.vector
      blockPosition = player.position.blockUnderneath
      chunkSectionPosition = player.position.chunkSection
      pitch = MathUtil.degrees(from: player.rotation.pitch)
      yaw = MathUtil.degrees(from: player.rotation.yaw)
      heading = player.rotation.heading
      gamemode = player.gamemode.gamemode
    }
    blockPosition.y += 1

    // Slow down updating of render stats to be easier to read
    if CFAbsoluteTimeGetCurrent() - lastFPSUpdate > fpsUpdateInterval {
      lastFPSUpdate = CFAbsoluteTimeGetCurrent()
      savedRenderStatistics = renderStatistics
    }
    let renderStatistics = savedRenderStatistics

    // Version
    var leftList = GUIList(rowHeight: 9, renderRowBackground: true)
    leftList.add("Minecraft \(Constants.versionString) (Delta Client)")

    // FPS
    var theoreticalFPSString = ""
    if let theoreticalFPS = renderStatistics.averageTheoreticalFPS {
      theoreticalFPSString = " (\(theoreticalFPS) theoretical)"
    }
    let cpuTimeString = String(format: "%.02f", renderStatistics.averageCPUTime * 1000.0)
    var gpuTimeString = ""
    if let gpuTime = renderStatistics.averageGPUTime {
      gpuTimeString = String(format: ", %.02fms gpu", gpuTime)
    }
    let fpsString = String(format: "%.00f", renderStatistics.averageFPS)
    leftList.add("\(fpsString) fps\(theoreticalFPSString) (\(cpuTimeString)ms cpu\(gpuTimeString))")

    // Dimension
    leftList.add("Dimension: \(client.game.world.dimension.identifier)")
    leftList.add(spacer: 6)

    // Position
    let x = String(format: "%.02f", position.x)
    let y = String(format: "%.02f", position.y)
    let z = String(format: "%.02f", position.z)
    leftList.add("XYZ: \(x) / \(y) / \(z)")

    // Block under feet
    leftList.add("Block: \(blockPosition.x) \(blockPosition.y) \(blockPosition.z)")

    // Chunk section and relative position
    let relativePosition = blockPosition.relativeToChunkSection
    let relativePositionString = "\(relativePosition.x) \(relativePosition.y) \(relativePosition.z)"
    let chunkSectionString = "\(chunkSectionPosition.sectionX) \(chunkSectionPosition.sectionY) \(chunkSectionPosition.sectionZ)"
    leftList.add("Chunk: \(relativePositionString) in \(chunkSectionString)")

    // Heading and rotation
    let yawString = String(format: "%.01f", yaw)
    let pitchString = String(format: "%.01f", pitch)
    leftList.add("Facing: \(heading) (Towards \(heading.isPositive ? "positive" : "negative") \(heading.axis)) (\(yawString) / \(pitchString))")

    // Lighting (at foot level)
    var lightPosition = blockPosition
    lightPosition.y += 1
    let skyLightLevel = client.game.world.getSkyLightLevel(at: lightPosition)
    let blockLightLevel = client.game.world.getBlockLightLevel(at: lightPosition)
    leftList.add("Light: \(skyLightLevel) sky, \(blockLightLevel) block")

    // Biome
    let biome = client.game.world.getBiome(at: blockPosition)
    leftList.add("Biome: \(biome?.identifier.description ?? "not loaded")")

    // Gamemode
    leftList.add("Gamemode: \(gamemode.string)")

    // System information
    var rightList = GUIList(rowHeight: 9, renderRowBackground: true, alignment: .right)
    rightList.add("CPU: \(Self.cpuName ?? "unknown") (\(Self.cpuArch ?? "n/a"))")
    rightList.add("Total mem: \(Self.totalMem)GB")
    rightList.add("GPU: \(Self.gpuInfo ?? "unknown")")

    root.add(leftList, .position(2, 3))
    root.add(rightList, .top(3), .right(2))
  }

  mutating func meshes(
    effectiveDrawableSize: Vec2i
  ) throws -> [GUIElementMesh] {
    profiler.push(.updateContent)
    let root = update(effectiveDrawableSize)
    profiler.pop()

    profiler.push(.createMeshes)
    let meshes = try root.meshes(context: context)
    profiler.pop()

    return meshes
  }
}
