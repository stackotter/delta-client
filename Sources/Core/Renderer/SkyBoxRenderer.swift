import MetalKit
import DeltaCore

/// The sky box consists of a sky plane (above the player), and a void plane
/// (below the player if the player is below the void plane visibility threshold).
/// It also includes distance fog cast on the planes which is what creates the
/// smooth transition from the fog color at the horizon to the sky color overhead.
public final class SkyBoxRenderer: Renderer {
  private var client: Client

  private var renderPipelineState: MTLRenderPipelineState

  private var skyPlaneVertexBuffer: MTLBuffer
  private var skyPlaneIndexBuffer: MTLBuffer
  private var skyPlaneUniformsBuffer: MTLBuffer
  private var voidPlaneUniformsBuffer: MTLBuffer

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

  private static let superFlatVoidPlaneVisibilityThreshold: Float = 1
  private static let defaultVoidPlaneVisibilityThreshold: Float = 63

  public init(client: Client, device: MTLDevice) throws {
    self.client = client

    let library = try MetalUtil.loadDefaultLibrary(device)
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "SkyBoxRenderer",
      vertexFunction: try MetalUtil.loadFunction("skyVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("skyFragment", from: library),
      blendingEnabled: false
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

    // Below 4 render distance the sky plane doesn't get rendered anymore.
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
    var (position, skyColor, fogColor) = client.game.accessPlayer { player in
      let position = player.ray.origin
      let blockPosition = BlockPosition(x: Int(position.x), y: Int(position.y), z: Int(position.z))

      let skyColor = client.game.world.getSkyColor(at: blockPosition)
      let fogColor = client.game.world.getFogColor(
        at: position,
        withRenderDistance: renderDistance
      )

      return (
        position,
        skyColor,
        fogColor
      )
    }

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

    encoder.setRenderPipelineState(renderPipelineState)
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

    let voidPlaneVisibilityThreshold = client.game.world.isFlat
      ? Self.superFlatVoidPlaneVisibilityThreshold
      : Self.defaultVoidPlaneVisibilityThreshold

    if position.y <= voidPlaneVisibilityThreshold {
      // Flip the plane to avoid it getting culled by backface culling.
      let transformation = MatrixUtil.rotationMatrix(.pi, around: .y)
        * MatrixUtil.translationMatrix(Vec3f(0, Self.voidPlaneOffset, 0))
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
}
