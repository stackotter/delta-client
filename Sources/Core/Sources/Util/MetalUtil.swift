import Metal
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
    guard let bundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/DeltaCore_DeltaCore.bundle")) else {
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
  public static func makeBuffer(_ device: MTLDevice, bytes: UnsafeRawPointer, length: Int, options: MTLResourceOptions, label: String? = nil) throws -> MTLBuffer {
    guard let buffer = device.makeBuffer(bytes: bytes, length: length, options: options) else {
      throw RenderError.failedToCreateBuffer(label: label)
    }
    
    buffer.label = label
    return buffer
  }
  
  /// Creates an empty buffer.
  /// - Parameters:
  ///   - device: Device to create the buffer with.
  ///   - length: Length of the buffer.
  ///   - options: Resource options for the buffer.
  ///   - label: Label to give the buffer.
  /// - Returns: An empty buffer.
  public static func makeBuffer(_ device: MTLDevice, length: Int, options: MTLResourceOptions, label: String? = nil) throws -> MTLBuffer {
    guard let buffer = device.makeBuffer(length: length, options: options) else {
      throw RenderError.failedToCreateBuffer(label: label)
    }
    
    buffer.label = label
    return buffer
  }
}
