import Foundation
import MetalKit
import DeltaCore

/// The renderer managing offscreen rendering and displaying final result in view.
public final class ScreenRenderer: Renderer {
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
      targetDepthTexture: renderTargetDepthTexture!,
      clearColour: MTLClearColorMake(0.65, 0.8, 1, 1) // Sky colour
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

    // A quad with total of 6 vertices (2 overlapping triangles) is drawn to present rendering results on-screen.
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    profiler.pop()
  }
}
