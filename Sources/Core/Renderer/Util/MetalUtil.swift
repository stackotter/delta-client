import Metal
import DeltaCore // TODO: remove this import once RenderError is in the Renderer target

public enum MetalUtil {
  /// Makes a render pipeline state with the given properties.
  public static func makeRenderPipelineState(
    device: MTLDevice,
    label: String,
    vertexFunction: MTLFunction,
    fragmentFunction: MTLFunction,
    blendingEnabled: Bool,
    editDescriptor: ((MTLRenderPipelineDescriptor) -> Void)? = nil,
    isOffScreenPass: Bool = true
  ) throws -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.label = label
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.depthAttachmentPixelFormat = .depth32Float

    // Optionally include accumulation and revealage buffers for order independent transparency
    if isOffScreenPass {
      descriptor.colorAttachments[1].pixelFormat = .bgra8Unorm
      descriptor.colorAttachments[2].pixelFormat = .r8Unorm
    }

    if blendingEnabled {
      descriptor.colorAttachments[0].isBlendingEnabled = true
      descriptor.colorAttachments[0].rgbBlendOperation = .add
      descriptor.colorAttachments[0].alphaBlendOperation = .add
      descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
      descriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
      descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
      descriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
    }

    editDescriptor?(descriptor)

    do {
      return try device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
      // TODO: Update error name
      throw RenderError.failedToCreateEntityRenderPipelineState(error, label: label)
    }
  }

  /// Loads the default metal library from the app bundle.
  ///
  /// The default library is at `DeltaClient.app/Contents/Resources/DeltaCore_DeltaCore.bundle/Resources/default.metallib`.
  public static func loadDefaultLibrary(_ device: MTLDevice) throws -> MTLLibrary {
    #if os(macOS)
    let bundlePath = "Contents/Resources/DeltaCore_DeltaRenderer.bundle"
    #elseif os(iOS) || os(tvOS)
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
  /// - Parameters:
  ///   - device: Device to create the state with.
  ///   - readOnly: If `true`, the depth texture will not be written to.
  /// - Returns: A depth stencil state.
  public static func createDepthState(device: MTLDevice, readOnly: Bool = false) throws -> MTLDepthStencilState {
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = !readOnly

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

  public static func createTexture(
    device: MTLDevice,
    width: Int,
    height: Int,
    pixelFormat: MTLPixelFormat,
    editDescriptor: ((MTLTextureDescriptor) -> Void)? = nil
  ) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor()
    descriptor.usage = [.shaderRead, .renderTarget]
    descriptor.width = width
    descriptor.height = height
    descriptor.pixelFormat = pixelFormat

    editDescriptor?(descriptor)

    guard let texture = device.makeTexture(descriptor: descriptor) else {
      throw RenderError.failedToUpdateRenderTargetSize
    }

    return texture
  }

  /// Creates a buffer on the GPU containing a given array. Reuses the supplied private buffer if it's big enough.
  /// - Returns: A new private buffer.
  public static func createPrivateBuffer<T>(
    labelled label: String = "buffer",
    containing items: [T],
    reusing existingBuffer: MTLBuffer? = nil,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws -> MTLBuffer {
    precondition(existingBuffer?.storageMode == .private || existingBuffer == nil, "existingBuffer must have a storageMode of private")

    // First copy the array to a scratch buffer (accessible from both CPU and GPU)
    let bufferSize = MemoryLayout<T>.stride * items.count
    guard let sharedBuffer = device.makeBuffer(bytes: items, length: bufferSize, options: [.storageModeShared]) else {
      throw RenderError.failedToCreateBuffer(label: label)
    }

    // Create a private buffer (only accessible from GPU) or reuse the existing buffer if possible
    let privateBuffer: MTLBuffer
    if let existingBuffer = existingBuffer, existingBuffer.length >= bufferSize {
//      log.trace("Reusing existing metal \(label)")
      privateBuffer = existingBuffer
    } else {
//      log.trace("Creating new metal \(label)")
      guard let buffer = device.makeBuffer(length: bufferSize, options: [.storageModePrivate]) else {
        throw RenderError.failedToCreateBuffer(label: label)
      }
      privateBuffer = buffer
    }
    privateBuffer.label = label

    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw RenderError.failedToCreateBlitCommandEncoder
    }

    // Encode and commit a blit operation to copy the contents of the scratch buffer into the private buffer
    encoder.copy(
      from: sharedBuffer,
      sourceOffset: 0,
      to: privateBuffer,
      destinationOffset: 0,
      size: bufferSize
    )
    encoder.endEncoding()
    commandBuffer.commit()

    return privateBuffer
  }
}
