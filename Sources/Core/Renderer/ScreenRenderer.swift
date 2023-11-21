import Foundation
import MetalKit
import DeltaCore
import FirebladeMath

/// The renderer managing offscreen rendering and displaying final result in view.
public final class ScreenRenderer: Renderer {
  /// The fog color used when the player's eyes are in lava.
  public static let lavaFogColor: Vec3f = Vec3f(0.6, 0.1, 0)

  /// The device used to render.
  private var device: MTLDevice

  /// Renderer's own pipeline state (for drawing on-screen)
  private var pipelineState: MTLRenderPipelineState

  /// Offscreen render pass descriptor used to perform rendering into renderer's internal textures
  private var offScreenRenderPassDescriptor: MTLRenderPassDescriptor!

  /// Renderer's profiler
  private var profiler: Profiler<RenderingMeasurement>

  /// Render target texture into which offscreen rendering is performed
  private var renderTargetTexture: MTLTexture?

  /// Render target depth texture
  private var renderTargetDepthTexture: MTLTexture?

  /// The accumulation texture used for rendering of order independent transparency.
  private var transparencyAccumulationTexture: MTLTexture?

  /// The revealage texture used for rendering of order independent transparency.
  private var transparencyRevealageTexture: MTLTexture?

  /// The uniforms used to render distance fog.
  private var fogUniformsBuffer: MTLBuffer

  /// Client for which rendering is performed
  private var client: Client

  public init(
    client: Client,
    device: MTLDevice,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.device = device
    self.client = client
    self.profiler = profiler

    // Create pipeline state
    let library = try MetalUtil.loadDefaultLibrary(device)
    pipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "ScreenRenderer",
      vertexFunction: try MetalUtil.loadFunction("screenVertexFunction", from: library),
      fragmentFunction: try MetalUtil.loadFunction("screenFragmentFunction", from: library),
      blendingEnabled: false,
      isOffScreenPass: false
    )

    fogUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<FogUniforms>.stride,
      options: .storageModeShared
    )
  }

  public var renderDescriptor: MTLRenderPassDescriptor {
    return offScreenRenderPassDescriptor
  }

  public func updateRenderTarget(for view: MTKView) throws {
    let drawableSize = view.drawableSize
    let width = Int(drawableSize.width)
    let height = Int(drawableSize.height)

    if let texture = renderTargetTexture {
      if texture.width == width && texture.height == height {
        // No updates necessary, early exit
        return
      }
    }

    renderTargetTexture = try MetalUtil.createTexture(
      device: device,
      width: width,
      height: height,
      pixelFormat: view.colorPixelFormat
    ) { descriptor in
      descriptor.storageMode = .private
    }

    renderTargetDepthTexture = try MetalUtil.createTexture(
      device: device,
      width: width,
      height: height,
      pixelFormat: .depth32Float
    ) { descriptor in
      descriptor.storageMode = .private
    }

    // Create accumulation texture for order independent transparency
    transparencyAccumulationTexture = try MetalUtil.createTexture(
      device: device,
      width: width,
      height: height,
      pixelFormat: .bgra8Unorm
    )

    // Create revealage texture for order independent transparency
    transparencyRevealageTexture = try MetalUtil.createTexture(
      device: device,
      width: width,
      height: height,
      pixelFormat: .r8Unorm
    )

    // Update render pass descriptor. Set clear colour to sky colour
    let passDescriptor = MetalUtil.createRenderPassDescriptor(
      device,
      targetRenderTexture: renderTargetTexture!,
      targetDepthTexture: renderTargetDepthTexture!
    )

    let accumulationClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    passDescriptor.colorAttachments[1].texture = transparencyAccumulationTexture
    passDescriptor.colorAttachments[1].clearColor = accumulationClearColor
    passDescriptor.colorAttachments[1].loadAction = MTLLoadAction.clear
    passDescriptor.colorAttachments[1].storeAction = MTLStoreAction.store

    let revealageClearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 0)
    passDescriptor.colorAttachments[2].texture = transparencyRevealageTexture
    passDescriptor.colorAttachments[2].clearColor = revealageClearColor
    passDescriptor.colorAttachments[2].loadAction = MTLLoadAction.clear
    passDescriptor.colorAttachments[2].storeAction = MTLStoreAction.store

    offScreenRenderPassDescriptor = passDescriptor
  }

  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // TODO: Investigate using a blit operation instead.

    profiler.push(.encode)
    // Set pipeline for rendering on-screen
    encoder.setRenderPipelineState(pipelineState)

    // Use texture from offscreen rendering as fragment shader source to draw contents on-screen
    encoder.setFragmentTexture(self.renderTargetTexture, index: 0)
    encoder.setFragmentTexture(self.renderTargetDepthTexture, index: 1)

    var fogUniforms = Self.fogUniforms(client: client, camera: camera)
    fogUniformsBuffer.contents().copyMemory(from: &fogUniforms, byteCount: MemoryLayout<FogUniforms>.size)
    encoder.setFragmentBuffer(fogUniformsBuffer, offset: 0, index: 0)

    // A quad with total of 6 vertices (2 overlapping triangles) is drawn to present
    // rendering results on-screen. The geometry is defined within the shader (hard-coded).
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    profiler.pop()
  }

  static func fogUniforms(client: Client, camera: Camera) -> FogUniforms {
    return client.game.accessPlayer { player in
      let position = EntityPosition(Vec3d(player.ray.origin))
      let biome = client.game.world.getBiome(at: position.block) ?? RegistryStore.shared.biomeRegistry.biome(for: Identifier(name: "plains"))!

      let block = client.game.world.getBlock(at: position.block)
      let fluidOnEyes = client.game.world.getFluidState(at: player.ray.origin)
        .map(\.fluidId)
        .map(RegistryStore.shared.fluidRegistry.fluid(withId:))

      let renderDistance = Float(max(client.configuration.render.renderDistance - 1, 2))

      var fogColor: Vec3f
      if fluidOnEyes?.isWater == true {
        // TODO: Slowly adjust the water fog color as the player's 'eyes' adjust
        fogColor = biome.waterFogColor.floatVector
      } else if fluidOnEyes?.isLava == true {
        fogColor = Self.lavaFogColor
      } else {
        fogColor = MathUtil.lerp(
          from: biome.fogColor.floatVector,
          to: biome.skyColor.floatVector,
          progress: 1 - FirebladeMath.pow(0.25 + 0.75 * min(32, renderDistance) / 32, 0.25)
        )
      }

      // As the player nears the 
      let voidFadeStart: Float = client.game.world.isFlat ? 1 : 32
      if player.ray.origin.y < voidFadeStart {
        let amount = player.ray.origin.y / voidFadeStart
        fogColor *= amount * amount 
      }

      // TODO: Check fog color reverse engineering document for any other adjustments
      //   to implement.
      // TODO: If player has blindness, the fog starts at 5/4 and ends at 5, lerping up to
      //   starting at renderDistance/4 and ending at renderDistance over the last second of blindness
      let fogStart: Float
      let fogEnd: Float
      if fluidOnEyes?.isWater == true {
        // TODO: Use exponential fog underwater
        fogStart = 16
        fogEnd = 32
      } else if fluidOnEyes?.isLava == true {
        // TODO: Should start at 0 and end at 3 if the player has fire resistance
        fogStart = 0.25
        fogEnd = 1
      } else if client.game.world.dimension.isNether {
        // TODO: This should also happen if there is a boss present which has the fog creation effect
        //   (determined by flags of BossBarPacket)
        fogStart = renderDistance / 20 * Float(Chunk.width)
        fogEnd = min(96, renderDistance / 2) * Float(Chunk.width)
      } else {
        fogStart = 0.75 * renderDistance * Float(Chunk.width)
        fogEnd = renderDistance * Float(Chunk.width)
      }

      return FogUniforms(
        inverseProjection: (camera.playerToCamera * camera.cameraToClip).inverted,
        nearPlane: camera.nearDistance,
        farPlane: camera.farDistance,
        fogStart: fogStart,
        fogEnd: fogEnd,
        fogColor: Vec4f(fogColor, 1)
      )
    }
  }
}
