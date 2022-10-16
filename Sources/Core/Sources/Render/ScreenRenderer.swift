import Foundation
import MetalKit

/// The renderer managing offscreen rendering and displaying final result in view.
public final class ScreenRenderer: Renderer {
  // MARK: - Private properties
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
  
  /// Client for which rendering is performed
  private var client: Client
  
  // MARK: - Init
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
      blendingEnabled: false
    )
  }
  
  // MARK: - Public
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
    
    let nativeRenderTextureDescriptor = MTLTextureDescriptor()
    nativeRenderTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
    nativeRenderTextureDescriptor.width = width
    nativeRenderTextureDescriptor.height = height
    nativeRenderTextureDescriptor.pixelFormat = view.colorPixelFormat
    guard let colourTexture = device.makeTexture(descriptor: nativeRenderTextureDescriptor) else {
      throw RenderError.failedToUpdateRenderTargetSize
    }
    
    // Update pixel format for depth texture. Match other texture parameters with colour attachment (above).
    nativeRenderTextureDescriptor.pixelFormat = .depth32Float
    guard let depthTexture = device.makeTexture(descriptor: nativeRenderTextureDescriptor) else {
      throw RenderError.failedToUpdateRenderTargetSize
    }
    
    // Update internal colour and depth textures
    self.renderTargetTexture = colourTexture
    self.renderTargetDepthTexture = depthTexture
    
    // Update render pass descriptor. Set clear colour to sky colour
    offScreenRenderPassDescriptor = MetalUtil.createRenderPassDescriptor(
      device,
      targetRenderTexture: renderTargetTexture!,
      targetDepthTexture: renderTargetDepthTexture!,
      clearColour: MTLClearColorMake(0.65, 0.8, 1, 1) // Sky colour
    )
  }
  
  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
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
