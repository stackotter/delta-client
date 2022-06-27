import Metal
import simd

struct GUI {
  var elements: [GUIElement] = []
  var font: Font
  var client: Client

  var showDebugScreen = false
  var renderStatistics = RenderStatistics(gpuCountersEnabled: false)

  var fpsUpdateInterval = 0.4
  var lastFPSUpdate: CFAbsoluteTime = 0
  var savedRenderStatistics = RenderStatistics(gpuCountersEnabled: false)

  init(client: Client) {
    font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    self.client = client
    elements = []

    populate()
  }

  mutating func populate() {
    elements = []
    if showDebugScreen {
      elements.append(contentsOf: debugScreen())
    }
  }

  mutating func debugScreen() -> [GUIElement] {
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
    var listBuilder = GUIListBuilder(x: 4, y: 4, spacing: 2)
    listBuilder.add("Minecraft \(Constants.versionString) (Delta Client)")

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
    listBuilder.add("\(fpsString) fps\(theoreticalFPSString) (\(cpuTimeString)ms cpu\(gpuTimeString))")

    // Dimension
    listBuilder.add("Dimension: \(client.game.world.dimension)")
    listBuilder.add(spacer: 6)

    // Position
    let x = String(format: "%.02f", position.x)
    let y = String(format: "%.02f", position.y)
    let z = String(format: "%.02f", position.z)
    listBuilder.add("XYZ: \(x) / \(y) / \(z)")

    // Block under feet
    listBuilder.add("Block: \(blockPosition.x) \(blockPosition.y) \(blockPosition.z)")

    // Chunk section and relative position
    let relativePosition = blockPosition.relativeToChunk
    let relativePositionString = "\(relativePosition.x) \(relativePosition.y) \(relativePosition.z)"
    let chunkSectionString = "\(chunkSectionPosition.sectionX) \(chunkSectionPosition.sectionY) \(chunkSectionPosition.sectionZ)"
    listBuilder.add("Chunk: \(relativePositionString) in \(chunkSectionString)")

    // Heading and rotation
    let yawString = String(format: "%.01f", yaw)
    let pitchString = String(format: "%.01f", pitch)
    listBuilder.add("Facing: \(heading) (Towards \(heading.isPositive ? "positive" : "negative") \(heading.axis)) (\(yawString) / \(pitchString))")

    // Biome
    let biome = client.game.world.chunk(at: chunkSectionPosition.chunk)?.biome(at: blockPosition)
    listBuilder.add("Biome: \(biome?.identifier.description ?? "not loaded")")

    // Gamemode
    listBuilder.add("Gamemode: \(gamemode.string)")

    return listBuilder.elements
  }

  mutating func update() {
    populate()
  }

  func meshes(device: MTLDevice, scale: Float, effectiveDrawableSize: SIMD2<Float>) throws -> [GUIElementMesh] {
    var meshes: [GUIElementMesh] = []
    for element in elements {
      var mesh: GUIElementMesh
      switch element.content {
        case .text(let text):
          mesh = try GUIElementMesh(text: text, font: font, device: device)
      }

      let x: Float
      switch element.constraints.horizontal {
        case .left(let distance):
          x = Float(distance)
        case .center:
          x = (effectiveDrawableSize.x - mesh.width) / 2
        case .right(let distance):
          x = effectiveDrawableSize.x - mesh.width - Float(distance)
      }

      let y: Float
      switch element.constraints.vertical {
        case .top(let distance):
          y = Float(distance)
        case .center:
          y = (effectiveDrawableSize.y - mesh.height) / 2
        case .bottom(let distance):
          y = effectiveDrawableSize.y - mesh.height - Float(distance)
      }

      mesh.position = [x, y]

      meshes.append(mesh)
    }

    return meshes
  }
}
