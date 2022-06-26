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

      let biome = client.game.world.chunk(at: chunkSectionPosition.chunk)?.biome(at: blockPosition)
      let x = String(format: "%.02f", position.x)
      let y = String(format: "%.02f", position.y)
      let z = String(format: "%.02f", position.z)
      let relativePosition = blockPosition.relativeToChunk
      let relativePositionString = "\(relativePosition.x) \(relativePosition.y) \(relativePosition.z)"
      let chunkSectionString = "\(chunkSectionPosition.sectionX) \(chunkSectionPosition.sectionY) \(chunkSectionPosition.sectionZ)"
      let yawString = String(format: "%.01f", yaw)
      let pitchString = String(format: "%.01f", pitch)
      let theoreticalFPSString: String
      if let theoreticalFPS = renderStatistics.averageTheoreticalFPS {
        theoreticalFPSString = " (\(theoreticalFPS) theoretical)"
      } else {
        theoreticalFPSString = ""
      }
      let cpuTime = renderStatistics.averageCPUTime * 1000.0
      let cpuTimeString = String(format: "%.02f", cpuTime)

      let gpuTimeString: String
      if let gpuTime = renderStatistics.averageGPUTime {
        gpuTimeString = String(format: ", %.02fms gpu", gpuTime)
      } else {
        gpuTimeString = ""
      }
      let fpsString = String(format: "%.00f", renderStatistics.averageFPS)

      elements = [
        GUIElement(.text("Minecraft \(Constants.versionString) (Delta Client)"), .position(4, 4)),
        GUIElement(.text("\(fpsString) fps\(theoreticalFPSString) (\(cpuTimeString)ms cpu\(gpuTimeString))"), .position(4, 14)),
        GUIElement(.text("Dimension: \(client.game.world.dimension)"), .position(4, 24)),

        GUIElement(.text("XYZ: \(x) / \(y) / \(z)"), .position(4, 44)),
        GUIElement(.text("Block: \(blockPosition.x) \(blockPosition.y) \(blockPosition.z)"), .position(4, 54)),
        GUIElement(.text("Chunk: \(relativePositionString) in \(chunkSectionString)"), .position(4, 64)),
        GUIElement(.text("Facing: \(heading) (Towards \(heading.isPositive ? "positive" : "negative") \(heading.axis)) (\(yawString) / \(pitchString))"), .position(4, 74)),
        GUIElement(.text("Biome: \(biome?.identifier.description ?? "not loaded")"), .position(4, 84)),
        GUIElement(.text("Gamemode: \(gamemode.string)"), .position(4, 94))
      ]
    }
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
