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

  private var skyPlaneVertexBuffer: MTLBuffer
  private var skyPlaneIndexBuffer: MTLBuffer
  private var skyPlaneUniformsBuffer: MTLBuffer
  private var voidPlaneUniformsBuffer: MTLBuffer

  private var sunriseDiscVertexBuffer: MTLBuffer
  private var sunriseDiscIndexBuffer: MTLBuffer
  private var sunriseDiscUniformsBuffer: MTLBuffer

  /// The vertices for the sky plane quad (also used for the void plane).
  private static var skyPlaneVertices: [Vec3f] = [
    Vec3f(-384, 0, 384),
    Vec3f(384, 0, 384),
    Vec3f(384, 0, -384),
    Vec3f(-384, 0, -384)
  ]
  /// The indices for the sky plane quad.
  private static var skyPlaneIndices: [UInt32] = [0, 1, 2, 2, 3, 0]

  /// The vertical offset of the sky plane relative to the camera.
  private static let skyPlaneOffset: Float = 16
  /// The vertical offset of the void plane relative to the camera.
  private static let voidPlaneOffset: Float = -4

  /// The y-level at which the void plane becomes visible in superflat worlds.
  private static let superFlatVoidPlaneVisibilityThreshold: Float = 1
  /// The y-level at which the void plane becomes visible in all worlds other than
  /// superflat worlds.
  private static let defaultVoidPlaneVisibilityThreshold: Float = 63

  public init(client: Client, device: MTLDevice) throws {
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

    // TODO: Make these both private once that's simpler to do (aft erMetalUtil
    //   rewrite/replacement)
    skyPlaneVertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &Self.skyPlaneVertices,
      length: Self.skyPlaneVertices.count * MemoryLayout<Vec3f>.stride,
      options: .storageModeShared,
      label: "skyPlaneVertexBuffer"
    )

    skyPlaneIndexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &Self.skyPlaneIndices,
      length: Self.skyPlaneIndices.count * MemoryLayout<UInt32>.stride,
      options: .storageModeShared,
      label: "skyPlaneIndexBuffer"
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

    let transformation = MatrixUtil.translationMatrix(Vec3f(0, Self.skyPlaneOffset, 0))
      * camera.playerToCamera
      * camera.cameraToClip

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
      transformation: transformation
    )

    skyPlaneUniformsBuffer.contents().copyMemory(
      from: &skyPlaneUniforms,
      byteCount: MemoryLayout<SkyPlaneUniforms>.stride
    )

    encoder.setRenderPipelineState(skyPlaneRenderPipelineState)
    encoder.setVertexBuffer(skyPlaneVertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(skyPlaneUniformsBuffer, offset: 0, index: 1)
    encoder.setFragmentBuffer(skyPlaneUniformsBuffer, offset: 0, index: 0)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.skyPlaneIndices.count,
      indexType: .uint32,
      indexBuffer: skyPlaneIndexBuffer,
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

    // Render the void plane if visible.
    let voidPlaneVisibilityThreshold = client.game.world.isFlat
      ? Self.superFlatVoidPlaneVisibilityThreshold
      : Self.defaultVoidPlaneVisibilityThreshold

    if position.y <= voidPlaneVisibilityThreshold {
      let transformation = MatrixUtil.translationMatrix(Vec3f(0, Self.voidPlaneOffset, 0))
        * camera.playerToCamera
        * camera.cameraToClip

      var voidPlaneUniforms = SkyPlaneUniforms(
        skyColor: Vec4f(0, 0, 0, 1),
        fogColor: Vec4f(fogColor, 1),
        fogStart: 0,
        fogEnd: Float(renderDistance * Chunk.width),
        transformation: transformation
      )

      voidPlaneUniformsBuffer.contents().copyMemory(
        from: &voidPlaneUniforms,
        byteCount: MemoryLayout<SkyPlaneUniforms>.stride
      )

      encoder.setRenderPipelineState(skyPlaneRenderPipelineState)
      encoder.setVertexBuffer(skyPlaneVertexBuffer, offset: 0, index: 0)
      encoder.setVertexBuffer(voidPlaneUniformsBuffer, offset: 0, index: 1)
      encoder.setFragmentBuffer(voidPlaneUniformsBuffer, offset: 0, index: 0)

      encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: Self.skyPlaneIndices.count,
        indexType: .uint32,
        indexBuffer: skyPlaneIndexBuffer,
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
