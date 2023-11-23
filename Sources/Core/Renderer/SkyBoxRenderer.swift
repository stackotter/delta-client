import MetalKit
import DeltaCore

/// The sky box consists of a sky plane (above the player), and a void plane
/// (below the player if the player is below the void plane visibility threshold).
/// It also includes distance fog cast on the planes which is what creates the
/// smooth transition from the fog color at the horizon to the sky color overhead.
public final class SkyBoxRenderer: Renderer {
  private var client: Client

  private var skyPlaneRenderPipelineState: MTLRenderPipelineState
  private var sunriseDiscRenderPipelineState: MTLRenderPipelineState
  private var celestialBodyRenderPipelineState: MTLRenderPipelineState

  private var quadVertexBuffer: MTLBuffer
  private var quadIndexBuffer: MTLBuffer

  private var skyPlaneUniformsBuffer: MTLBuffer
  private var voidPlaneUniformsBuffer: MTLBuffer

  private var sunriseDiscVertexBuffer: MTLBuffer
  private var sunriseDiscIndexBuffer: MTLBuffer
  private var sunriseDiscUniformsBuffer: MTLBuffer

  private var sunUniformsBuffer: MTLBuffer
  private var moonUniformsBuffer: MTLBuffer

  private var environmentTexturePalette: MetalTexturePalette

  /// The vertices for the sky plane quad (also used for the void plane).
  private static var quadVertices: [Vec3f] = [
    Vec3f(-1, 0, 1),
    Vec3f(1, 0, 1),
    Vec3f(1, 0, -1),
    Vec3f(-1, 0, -1)
  ]
  /// The indices for the sky plane, void plane, sun, or moon quad.
  private static var quadIndices: [UInt32] = [0, 1, 2, 2, 3, 0]

  /// The vertical offset of the sky plane relative to the camera.
  private static let skyPlaneOffset: Float = 16
  /// The sky plane's size in blocks.
  private static let skyPlaneSize: Float = 768
  /// The void plane's size in blocks.
  private static let voidPlaneSize: Float = 768
  /// The vertical offset of the void plane relative to the camera.
  private static let voidPlaneOffset: Float = -4

  /// The sun's size in blocks.
  private static let sunSize: Float = 60
  /// The sun's distance from the camera.
  private static let sunDistance: Float = 100
  /// The moon's size in blocks.
  private static let moonSize: Float = 40
  /// The moon's distance from the camera.
  private static let moonDistance: Float = 100

  /// The y-level at which the void plane becomes visible in superflat worlds.
  private static let superFlatVoidPlaneVisibilityThreshold: Float = 1
  /// The y-level at which the void plane becomes visible in all worlds other than
  /// superflat worlds.
  private static let defaultVoidPlaneVisibilityThreshold: Float = 63

  public init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.client = client

    let library = try MetalUtil.loadDefaultLibrary(device)
    skyPlaneRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "SkyBoxRenderer.skyPlane",
      vertexFunction: try MetalUtil.loadFunction("skyPlaneVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("skyPlaneFragment", from: library),
      blendingEnabled: false
    )

    sunriseDiscRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "SkyBoxRenderer.sunriseDisc",
      vertexFunction: try MetalUtil.loadFunction("sunriseDiscVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("sunriseDiscFragment", from: library),
      blendingEnabled: true
    )

    celestialBodyRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "SkyBoxRenderer.celestialBody",
      vertexFunction: try MetalUtil.loadFunction("celestialBodyVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("celestialBodyFragment", from: library),
      blendingEnabled: true
    ) { descriptor in
      // The sun and moon textures just have their alpha set to one so they require
      // different blending to usual.
      descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
    }

    // TODO: Make these both private (storage mode) once that's simpler to do (after MetalUtil
    //   rewrite/replacement)
    quadVertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &Self.quadVertices,
      length: Self.quadVertices.count * MemoryLayout<Vec3f>.stride,
      options: .storageModeShared,
      label: "quadVertexBuffer"
    )

    quadIndexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &Self.quadIndices,
      length: Self.quadIndices.count * MemoryLayout<UInt32>.stride,
      options: .storageModeShared,
      label: "quadIndexBuffer"
    )

    skyPlaneUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<SkyPlaneUniforms>.stride,
      options: .storageModeShared,
      label: "skyPlaneUniformsBuffer"
    )

    voidPlaneUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<SkyPlaneUniforms>.stride,
      options: .storageModeShared,
      label: "skyPlaneUniformsBuffer"
    )

    var sunriseDiscVertices = Self.generateSunriseDiscVertices()
    sunriseDiscVertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &sunriseDiscVertices,
      length: sunriseDiscVertices.count * MemoryLayout<Vec3f>.stride,
      options: .storageModeShared,
      label: "sunriseDiscVertexBuffer"
    )

    var sunriseDiscIndices = Self.generateSunriseDiscIndices()
    sunriseDiscIndexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &sunriseDiscIndices,
      length: sunriseDiscIndices.count * MemoryLayout<UInt32>.stride,
      options: .storageModeShared,
      label: "sunriseDiscIndexBuffer"
    )

    sunriseDiscUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<SunriseDiscUniforms>.stride,
      options: .storageModeShared,
      label: "sunriseDiscUniformsBuffer"
    )

    sunUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<CelestialBodyUniforms>.stride,
      options: .storageModeShared,
      label: "sunUniformsBuffer"
    )

    moonUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<CelestialBodyUniforms>.stride,
      options: .storageModeShared,
      label: "moonUniformsBuffer"
    )

    environmentTexturePalette = try MetalTexturePalette(
      palette: client.resourcePack.vanillaResources.environmentTexturePalette,
      device: device,
      commandQueue: commandQueue
    )
  }

  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Only the overworld has a sky plane.
    guard client.game.world.dimension.isOverworld else {
      return
    }

    // Below 4 render distance the sky plane, void plane, and sunrises/sunsets
    // don't get rendered anymore.
    guard client.configuration.render.renderDistance >= 4 else {
      return
    }

    let playerToClip = camera.playerToCamera * camera.cameraToClip

    // When the render distance is above 2, move the fog 1 chunk closer to conceal
    // more of the world edge.
    let renderDistance = max(client.configuration.render.renderDistance - 1, 2)

    // TODO: Use camera position instead of player position. It'd remove the need for locking
    //   and a closure.
    let (position, skyColor, fogColor) = client.game.accessPlayer { player in
      let position = player.ray.origin
      let blockPosition = BlockPosition(x: Int(position.x), y: Int(position.y), z: Int(position.z))

      let skyColor = client.game.world.getSkyColor(at: blockPosition)
      let fogColor = client.game.world.getFogColor(
        forViewerWithRay: player.ray,
        withRenderDistance: renderDistance
      )

      return (
        position,
        skyColor,
        fogColor
      )
    }

    // Render the sky plane.
    var skyPlaneUniforms = SkyPlaneUniforms(
      skyColor: Vec4f(skyColor, 1),
      fogColor: Vec4f(fogColor, 1),
      fogStart: 0,
      fogEnd: Float(renderDistance * Chunk.width),
      size: Self.skyPlaneSize,
      verticalOffset: Self.skyPlaneOffset,
      playerToClip: playerToClip
    )

    skyPlaneUniformsBuffer.contents().copyMemory(
      from: &skyPlaneUniforms,
      byteCount: MemoryLayout<SkyPlaneUniforms>.stride
    )

    encoder.setRenderPipelineState(skyPlaneRenderPipelineState)
    encoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(skyPlaneUniformsBuffer, offset: 0, index: 1)
    encoder.setFragmentBuffer(skyPlaneUniformsBuffer, offset: 0, index: 0)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.quadIndices.count,
      indexType: .uint32,
      indexBuffer: quadIndexBuffer,
      indexBufferOffset: 0
    )

    // Render the sunrise/sunset disc if applicable.
    let daylightCyclePhase = client.game.world.getDaylightCyclePhase()
    switch daylightCyclePhase {
      case let .sunrise(color), let .sunset(color):
        let rotation: Mat4x4f
        if daylightCyclePhase.isSunrise {
          rotation = MatrixUtil.identity
        } else {
          rotation = MatrixUtil.rotationMatrix(.pi, around: .y)
        }

        let transformation = rotation
          * camera.playerToCamera
          * camera.cameraToClip

        var sunriseDiscUniforms = SunriseDiscUniforms(
          color: color,
          transformation: transformation
        )

        sunriseDiscUniformsBuffer.contents().copyMemory(
          from: &sunriseDiscUniforms,
          byteCount: MemoryLayout<SunriseDiscUniforms>.stride
        )

        encoder.setRenderPipelineState(sunriseDiscRenderPipelineState)
        encoder.setVertexBuffer(sunriseDiscVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(sunriseDiscUniformsBuffer, offset: 0, index: 1)

        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: sunriseDiscIndexBuffer.length / MemoryLayout<UInt32>.stride,
          indexType: .uint32,
          indexBuffer: sunriseDiscIndexBuffer,
          indexBufferOffset: 0
        )
      case .day, .night:
        break
    }

    // TODO: Make a similar system to the GUITexturePalette system where certain
    //   textures are guaranteed to be present. Also have a way to get UV bounds
    //   for specific 'sprites'.
    // Render the sun
    let sunTextureIndex = UInt16(
      environmentTexturePalette.textureIndex(
        for: Identifier(name: "environment/sun")
      )!
    )
    var sunUniforms = CelestialBodyUniforms(
      transformation:
        MatrixUtil.scalingMatrix(Self.sunSize / 2)
          * MatrixUtil.translationMatrix(Vec3f(0, Self.sunDistance, 0))
          * MatrixUtil.rotationMatrix(-.pi / 2, around: .y)
          * MatrixUtil.rotationMatrix(client.game.world.getSunAngleRadians(), around: .z)
          * playerToClip,
      textureIndex: sunTextureIndex,
      uvPosition: Vec2f(0, 0),
      uvSize: Vec2f(1/8, 1/8),
      type: .sun
    )

    sunUniformsBuffer.contents().copyMemory(
      from: &sunUniforms,
      byteCount: MemoryLayout<CelestialBodyUniforms>.stride
    )

    encoder.setRenderPipelineState(celestialBodyRenderPipelineState)
    encoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(sunUniformsBuffer, offset: 0, index: 1)
    encoder.setFragmentTexture(environmentTexturePalette.arrayTexture, index: 0)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.quadIndices.count,
      indexType: .uint32,
      indexBuffer: quadIndexBuffer,
      indexBufferOffset: 0
    )

    // Render the moon
    let moonPhase = client.game.world.getMoonPhase()
    let moonUVPosition = Vec2f(
      Float(moonPhase % 4) * 1/8,
      Float(moonPhase / 4) * 1/8
    )
    let moonTextureIndex = UInt16(
      environmentTexturePalette.textureIndex(
        for: Identifier(name: "environment/moon_phases")
      )!
    )
    var moonUniforms = CelestialBodyUniforms(
      transformation:
        MatrixUtil.scalingMatrix(Self.moonSize / 2)
          * MatrixUtil.translationMatrix(Vec3f(0, Self.moonDistance, 0))
          * MatrixUtil.rotationMatrix(-.pi / 2, around: .y)
          * MatrixUtil.rotationMatrix(client.game.world.getSunAngleRadians() + .pi, around: .z)
          * playerToClip,
      textureIndex: moonTextureIndex,
      uvPosition: moonUVPosition,
      uvSize: Vec2f(1/8, 1/8),
      type: .sun
    )

    moonUniformsBuffer.contents().copyMemory(
      from: &moonUniforms,
      byteCount: MemoryLayout<CelestialBodyUniforms>.stride
    )

    encoder.setVertexBuffer(moonUniformsBuffer, offset: 0, index: 1)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.quadIndices.count,
      indexType: .uint32,
      indexBuffer: quadIndexBuffer,
      indexBufferOffset: 0
    )

    // Render the void plane if visible.
    let voidPlaneVisibilityThreshold = client.game.world.isFlat
      ? Self.superFlatVoidPlaneVisibilityThreshold
      : Self.defaultVoidPlaneVisibilityThreshold

    if position.y <= voidPlaneVisibilityThreshold {
      var voidPlaneUniforms = SkyPlaneUniforms(
        skyColor: Vec4f(0, 0, 0, 1),
        fogColor: Vec4f(fogColor, 1),
        fogStart: 0,
        fogEnd: Float(renderDistance * Chunk.width),
        size: Self.voidPlaneSize,
        verticalOffset: Self.voidPlaneOffset,
        playerToClip: playerToClip
      )

      voidPlaneUniformsBuffer.contents().copyMemory(
        from: &voidPlaneUniforms,
        byteCount: MemoryLayout<SkyPlaneUniforms>.stride
      )

      encoder.setRenderPipelineState(skyPlaneRenderPipelineState)
      encoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
      encoder.setVertexBuffer(voidPlaneUniformsBuffer, offset: 0, index: 1)
      encoder.setFragmentBuffer(voidPlaneUniformsBuffer, offset: 0, index: 0)

      encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: Self.quadIndices.count,
        indexType: .uint32,
        indexBuffer: quadIndexBuffer,
        indexBufferOffset: 0
      )
    }
  }

  /// Generates the vertices for a triangle fan. Think of it like a pizza, which
  /// has a single central vertex which is touched by one corner of every slice.
  /// The triangle fan generated has 16 slices, with the central vertex being
  /// vertex 0, and the next 16 vertices forming a clockwise ring.
  static func generateSunriseDiscVertices() -> [Vec3f] {
    var vertices: [Vec3f] = [Vec3f(100, 0, 0)]
    for i in 0..<16 {
      let t = Float(i) / 16 * 2 * .pi
      vertices.append(Vec3f(
        120 * Foundation.cos(t),
        40 * Foundation.cos(t),
        120 * Foundation.sin(t)
      ))
    }
    return vertices
  }

  /// Generates the indices for a triangle fan. Think of it like a pizza, which
  /// has a single central vertex which is touched by one corner of every slice.
  /// The triangle fan is assumed to have 16 slices, with the central vertex
  /// being vertex 0, and the next 16 vertices forming a clockwise ring.
  static func generateSunriseDiscIndices() -> [UInt32] {
    var indices: [UInt32] = []
    for i in 0..<16 {
      indices.append(contentsOf: [
        0,
        UInt32(i) + 1,
        ((UInt32(i) + 1) % 16) + 1
      ])
    }
    return indices
  }
}
