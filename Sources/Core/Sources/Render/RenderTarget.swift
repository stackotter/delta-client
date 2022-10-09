import Foundation
import MetalKit

#if canImport(MetalFX)
  import MetalFX
#endif

/// The renderer for the GUI (chat, f3, scoreboard etc.).
public final class ScreenRenderer: Renderer {
  
  // MARK: - Internal
  /// Internal variable holding spatial scaler, it's availability depends on OS version and hardware support
  private var _spatialScaler: Any?
  
  // MARK: - Private properties
  /// The device used to render.
  private var device: MTLDevice
  private var supportsMetal3: Bool = false
  private var upscalingFactor: Int = -1
  private var pipelineState: MTLRenderPipelineState
  private var offscreenRenderPass: MTLRenderPassDescriptor!
  private var profiler: Profiler<RenderingMeasurement>
  
  private var renderTargetTexture: MTLTexture!
  private var renderTargetDepthTexture: MTLTexture!
  
  private var client: Client
  
  /// Spatial scaler from MetalFX used in spatial upscaling of render target
  @available(macOS 13, *)
  private var spatialScaler: MTLFXSpatialScaler? {
    get {
      return _spatialScaler as? MTLFXSpatialScaler
    }
    set {
      _spatialScaler = newValue
    }
  }
  
  // MARK: - Init
  public init(
    client: Client,
    device: MTLDevice,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.device = device
    self.client = client
    self.profiler = profiler
    
    // Check hardware capabilities for advanced features.
    if #available(macOS 13, iOS 16, *) {
      self.supportsMetal3 = self.device.supportsFamily(.metal3)
    }
    
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
  
  // MARK: - Public properties
  public var renderDescriptor: MTLRenderPassDescriptor {
    return offscreenRenderPass
  }
  
  public var renderOutputTexture: MTLTexture {
    get {
      return renderTargetTexture
    }
    set {
      renderTargetTexture = newValue
    }
  }
  
  public var renderDepthTexture: MTLTexture {
    get {
      return renderTargetDepthTexture
    }
    set {
      renderTargetDepthTexture = newValue
    }
  }
  
  public func updateRenderData(for view: MTKView) {
    let drawableSize = view.drawableSize
    let width = Int(drawableSize.width)
    let height = Int(drawableSize.height)
    
    if client.configuration.render.upscaleFactor != upscalingFactor ||
        renderOutputTexture.width != width ||
        renderOutputTexture.height != height {
      
      let nativeRenderTextureDescriptor = MTLTextureDescriptor()
      nativeRenderTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
      nativeRenderTextureDescriptor.width = width
      nativeRenderTextureDescriptor.height = height
      nativeRenderTextureDescriptor.pixelFormat = view.colorPixelFormat
      
      renderOutputTexture = device.makeTexture(descriptor: nativeRenderTextureDescriptor)!
      
      nativeRenderTextureDescriptor.pixelFormat = .depth32Float
      renderDepthTexture = device.makeTexture(descriptor: nativeRenderTextureDescriptor)!
      
      offscreenRenderPass = MetalUtil.createRenderPassDescriptor(
        device,
        targetRenderTexture: renderOutputTexture,
        targetDepthTexture: renderDepthTexture,
        clearColour: MTLClearColorMake(0.65, 0.8, 1, 1)
      )
      
    }
  }
  
  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    let drawableSize = view.drawableSize
    let width = Int(drawableSize.width)
    let height = Int(drawableSize.height)
    
    
    profiler.push(.encode)
    
    // Set pipeline
    encoder.setRenderPipelineState(pipelineState)
    encoder.setFragmentTexture(self.renderOutputTexture, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    profiler.pop()
  }
}
