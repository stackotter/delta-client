import Metal
import DeltaCore // TODO: remove this import once RenderError is in the Renderer target

public enum MetalUtil {
  /// Makes a render pipeline state with the given properties.
  public static func makeRenderPipelineState(
    device: MTLDevice,
    label: String,
    vertexFunction: MTLFunction,
    fragmentFunction: MTLFunction,
    blendingEnabled: Bool
  ) throws -> MTLRenderPipelineState {
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = label
    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

    if blendingEnabled {
      pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
      pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
      pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
      pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
      pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
      pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
      pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
    }

    do {
      return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      throw RenderError.failedToCreateEntityRenderPipelineState(error)
    }
  }

  /// Loads the default metal library from the app bundle.
  ///
  /// The default library is at `DeltaClient.app/Contents/Resources/DeltaCore_DeltaCore.bundle/Resources/default.metallib`.
  public static func loadDefaultLibrary(_ device: MTLDevice) throws -> MTLLibrary {
    #if os(macOS)
    let bundlePath = "Contents/Resources/DeltaCore_DeltaRenderer.bundle"
    #elseif os(iOS)
    let bundlePath = "DeltaCore_DeltaRenderer.bundle"
    #else
    #error("Unsupported platform, unknown DeltaCore bundle location")
    #endif

    guard let bundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent(bundlePath)) else {
      throw RenderError.failedToGetBundle
    }

    guard let libraryURL = bundle.url(forResource: "default", withExtension: "metallib") else {
      throw RenderError.failedToLocateMetallib
    }

    do {
      return try device.makeLibrary(URL: libraryURL)
    } catch {
      throw RenderError.failedToCreateMetallib(error)
    }
  }

  /// Loads a metal function from the given library.
  /// - Parameters:
  ///   - name: Name of the function.
  ///   - library: Library containing the function.
  /// - Returns: The function.
  public static func loadFunction(_ name: String, from library: MTLLibrary) throws -> MTLFunction {
    guard let function = library.makeFunction(name: name) else {
      log.warning("Failed to load shader: '\(name)'")
      throw RenderError.failedToLoadShaders
    }

    return function
  }

  /// Creates a populated buffer.
  /// - Parameters:
  ///   - device: Device to create the buffer with.
  ///   - bytes: Bytes to populate the buffer with.
  ///   - length: Length of the buffer.
  ///   - options: Resource options for the buffer
  ///   - label: Label to give the buffer.
  /// - Returns: A new buffer.
  public static func makeBuffer(
    _ device: MTLDevice,
    bytes: UnsafeRawPointer,
    length: Int,
    options: MTLResourceOptions,
    label: String? = nil
  ) throws -> MTLBuffer {
    guard let buffer = device.makeBuffer(bytes: bytes, length: length, options: options) else {
      throw RenderError.failedToCreateBuffer(label: label)
    }

    buffer.label = label
    return buffer
  }

  /// Creates a buffer for sampling the requested set of counters.
  /// - Parameters:
  ///   - device: The device that sampling will be performed on.
  ///   - commonCounterSet: The counter set that the buffer will be used to sample.
  ///   - sampleCount: The size of sampling buffer to create.
  /// - Returns: A buffer for storing counter samples.
  public static func makeCounterSampleBuffer(
    _ device: MTLDevice,
    counterSet commonCounterSet: MTLCommonCounterSet,
    sampleCount: Int
  ) throws -> MTLCounterSampleBuffer {
    var counterSet: MTLCounterSet?
    for deviceCounterSet in device.counterSets ?? [] {
      if deviceCounterSet.name.caseInsensitiveCompare(commonCounterSet.rawValue) == .orderedSame {
        counterSet = deviceCounterSet
        break
      }
    }

    guard let counterSet = counterSet else {
      throw RenderError.failedToGetCounterSet(commonCounterSet.rawValue)
    }

    let descriptor = MTLCounterSampleBufferDescriptor()
    descriptor.counterSet = counterSet
    descriptor.storageMode = .shared
    descriptor.sampleCount = sampleCount

    do {
      return try device.makeCounterSampleBuffer(descriptor: descriptor)
    } catch {
      throw RenderError.failedToMakeCounterSampleBuffer(error)
    }
  }

  /// Creates an empty buffer.
  /// - Parameters:
  ///   - device: Device to create the buffer with.
  ///   - length: Length of the buffer.
  ///   - options: Resource options for the buffer.
  ///   - label: Label to give the buffer.
  /// - Returns: An empty buffer.
  public static func makeBuffer(
    _ device: MTLDevice,
    length: Int,
    options: MTLResourceOptions,
    label: String? = nil
  ) throws -> MTLBuffer {
    guard let buffer = device.makeBuffer(length: length, options: options) else {
      throw RenderError.failedToCreateBuffer(label: label)
    }

    buffer.label = label
    return buffer
  }

  /// Creates a simple depth stencil state.
  /// - Parameter device: Device to create the state with.
  /// - Returns: A depth stencil state.
  public static func createDepthState(device: MTLDevice) throws -> MTLDepthStencilState {
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true

    guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
      throw RenderError.failedToCreateWorldDepthStencilState
    }

    return depthState
  }

  /// Creates a custom render pass descriptor with default clear / store actions.
  /// - Parameter device: Device to create the descriptor with.
  /// - Returns: A render pass descriptor with custom render targets.
  public static func createRenderPassDescriptor(
    _ device: MTLDevice,
    targetRenderTexture: MTLTexture,
    targetDepthTexture: MTLTexture,
    clearColour: MTLClearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
  ) -> MTLRenderPassDescriptor {
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = targetRenderTexture
    renderPassDescriptor.colorAttachments[0].clearColor = clearColour
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store

    renderPassDescriptor.depthAttachment.texture = targetDepthTexture
    renderPassDescriptor.depthAttachment.loadAction = MTLLoadAction.clear
    renderPassDescriptor.depthAttachment.storeAction = MTLStoreAction.store

    return renderPassDescriptor
  }
}
