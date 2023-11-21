import MetalKit
import DeltaCore

public final class SkyBoxRenderer: Renderer {
  private var client: Client

  private var renderPipelineState: MTLRenderPipelineState

  private var skyPlaneVertexBuffer: MTLBuffer
  private var skyPlaneIndexBuffer: MTLBuffer
  private var skyPlaneUniformsBuffer: MTLBuffer

  private static var skyPlaneVertices: [Vec3f] = [
    Vec3f(-384, 0, 384),
    Vec3f(384, 0, 384),
    Vec3f(384, 0, -384),
    Vec3f(-384, 0, -384)
  ]
  private static var skyPlaneIndices: [UInt32] = [0, 1, 2, 2, 3, 0]

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

    let transformation = MatrixUtil.translationMatrix(Vec3f(0, 16, 0))
      * camera.playerToCamera
      * camera.cameraToClip

    // When the render distance is above 2, move the fog 1 chunk closer to conceal
    // more of the world edge.
    let renderDistance = max(client.configuration.render.renderDistance - 1, 2)

    var (skyColor, fogColor) = client.game.accessPlayer { player in
      let position = player.ray.origin
      let blockPosition = BlockPosition(x: Int(position.x), y: Int(position.y), z: Int(position.z))

      let skyColor = client.game.world.getSkyColor(at: blockPosition)
      let fogColor = client.game.world.getFogColor(
        at: position,
        withRenderDistance: renderDistance
      )

      return (
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
  }
}
