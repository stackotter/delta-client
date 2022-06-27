import Metal
import simd

struct GUI {
  var root: GUIGroupElement
  var client: Client

  var showDebugScreen = false
  var renderStatistics = RenderStatistics(gpuCountersEnabled: false)

  var fpsUpdateInterval = 0.4
  var lastFPSUpdate: CFAbsoluteTime = 0
  var savedRenderStatistics = RenderStatistics(gpuCountersEnabled: false)

  var font: Font
  var fontArrayTexture: MTLTexture
  var guiTexturePalette: GUITexturePalette
  var guiArrayTexture: MTLTexture

  init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.client = client

    root = GUIGroupElement([0, 0])

    font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    fontArrayTexture = try font.createArrayTexture(device)

    guiTexturePalette = try GUITexturePalette(client.resourcePack.vanillaResources.guiTexturePalette)
    guiArrayTexture = try guiTexturePalette.palette.createTextureArray(
      device: device,
      animationState: ArrayTextureAnimationState(for: guiTexturePalette.palette),
      commandQueue: commandQueue
    )
  }

  mutating func update(_ screenSize: SIMD2<Int>) {
    root = GUIGroupElement(screenSize)

    // Debug screen
    if showDebugScreen {
      root.add(debugScreen(), .position(0, 0))
    }

    // Hot bar area (hot bar, health, food, etc.)
    root.add(hotbarArea(), .bottom(4), .center)

    // Render crosshair
    root.add(GUISprite.crossHair, .center)
  }

  func hotbarArea() -> GUIGroupElement {
    var group = GUIGroupElement([182, 9])
    var health: Float = 0
    var food: Int = 0
    var gamemode: Gamemode = .adventure
    client.game.accessPlayer { player in
      gamemode = player.gamemode.gamemode
      health = player.health.health
      food = player.nutrition.food
    }

    if gamemode.hasHealth {
      // Render health
      group.add(
        statBar(
          value: Int(health.rounded()),
          outline: .heartOutline,
          fullIcon: .fullHeart,
          halfIcon: .halfHeart,
          horizontalConstraint: HorizontalConstraint.left
        ),
        .bottom(0),
        .left(0)
      )

      // Render hunger
      group.add(
        statBar(
          value: food,
          outline: .foodOutline,
          fullIcon: .fullFood,
          halfIcon: .halfFood,
          horizontalConstraint: HorizontalConstraint.right
        ),
        .bottom(0),
        .right(0)
      )

      // Render armor amount
      // elements.append(contentsOf: statBar(
      //   value: food,
      //   outline: .armorOutline,
      //   fullIcon: .fullArmor,
      //   halfIcon: .halfArmor,
      //   horizontalConstraint: HorizontalConstraint.left,
      //   alwaysHasOutline: false
      // ))
    }

    return group
  }

  func statBar(
    value: Int,
    outline: GUISprite,
    fullIcon: GUISprite,
    halfIcon: GUISprite,
    horizontalConstraint: (Int) -> HorizontalConstraint,
    alwaysHasOutline: Bool = true
  ) -> GUIGroupElement {
    var group = GUIGroupElement([81, 9])

    let fullIconCount = value / 2
    let hasHalfIcon = value % 2 == 1
    for i in 0..<10 {
      // Outline
      let position = Constraints(.top(0), horizontalConstraint(i * 8))
      if alwaysHasOutline || i > fullIconCount {
        group.add(outline, position)
      }

      // Full and half icons
      if i < fullIconCount {
        group.add(fullIcon, position)
      } else if i == fullIconCount && hasHalfIcon {
        group.add(halfIcon, position)
      }
    }

    return group
  }

  mutating func debugScreen() -> GUIList {
    // Fetch relevant player properties
    var blockPosition = BlockPosition(x: 0, y: 0, z: 0)
    var chunkSectionPosition = ChunkSectionPosition(sectionX: 0, sectionY: 0, sectionZ: 0)
    var position: SIMD3<Double> = .zero
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

    // Slow down updating of render stats to be easier to read
    if CFAbsoluteTimeGetCurrent() - lastFPSUpdate > fpsUpdateInterval {
      lastFPSUpdate = CFAbsoluteTimeGetCurrent()
      savedRenderStatistics = renderStatistics
    }
    let renderStatistics = savedRenderStatistics

    // Version
    var list = GUIList(rowHeight: 10)
    list.add("Minecraft \(Constants.versionString) (Delta Client)")

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
    list.add("\(fpsString) fps\(theoreticalFPSString) (\(cpuTimeString)ms cpu\(gpuTimeString))")

    // Dimension
    list.add("Dimension: \(client.game.world.dimension)")
    list.add(spacer: 6)

    // Position
    let x = String(format: "%.02f", position.x)
    let y = String(format: "%.02f", position.y)
    let z = String(format: "%.02f", position.z)
    list.add("XYZ: \(x) / \(y) / \(z)")

    // Block under feet
    list.add("Block: \(blockPosition.x) \(blockPosition.y) \(blockPosition.z)")

    // Chunk section and relative position
    let relativePosition = blockPosition.relativeToChunk
    let relativePositionString = "\(relativePosition.x) \(relativePosition.y) \(relativePosition.z)"
    let chunkSectionString = "\(chunkSectionPosition.sectionX) \(chunkSectionPosition.sectionY) \(chunkSectionPosition.sectionZ)"
    list.add("Chunk: \(relativePositionString) in \(chunkSectionString)")

    // Heading and rotation
    let yawString = String(format: "%.01f", yaw)
    let pitchString = String(format: "%.01f", pitch)
    list.add("Facing: \(heading) (Towards \(heading.isPositive ? "positive" : "negative") \(heading.axis)) (\(yawString) / \(pitchString))")

    // Biome
    let biome = client.game.world.chunk(at: chunkSectionPosition.chunk)?.biome(at: blockPosition)
    list.add("Biome: \(biome?.identifier.description ?? "not loaded")")

    // Gamemode
    list.add("Gamemode: \(gamemode.string)")

    return list
  }

  mutating func meshes(
    effectiveDrawableSize: SIMD2<Int>
  ) throws -> [GUIElementMesh] {
    update(effectiveDrawableSize)
    let context = GUIContext(
      font: font,
      fontArrayTexture: fontArrayTexture,
      guiTexturePalette: guiTexturePalette,
      guiArrayTexture: guiArrayTexture
    )

    return try root.meshes(context: context)
  }
}
