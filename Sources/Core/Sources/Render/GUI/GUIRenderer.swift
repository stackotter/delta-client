import MetalKit

/// The renderer for the GUI (chat, f3, scoreboard etc.).
public struct GUIRenderer: Renderer {
  var device: MTLDevice
  var font: Font
  var scale: Float
  var fontArrayTexture: MTLTexture
  var quadIndexBuffer: MTLBuffer
  var quadVertexBuffer: MTLBuffer
  var uniformsBuffer: MTLBuffer
  var pipelineState: MTLRenderPipelineState
  var gui: GUI

  public init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.device = device

    // Create array texture
    font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    fontArrayTexture = try font.createArrayTexture(device)

    // Create quad geometry (for instancing)
    quadIndexBuffer = try GUIQuadGeometry.getIndexBuffer(device: device)
    quadVertexBuffer = try GUIQuadGeometry.getVertexBuffer(device: device)

    // Create uniforms buffer
    uniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<GUIUniforms>.stride,
      options: []
    )

    // Create pipeline state
    let library = try MetalUtil.loadDefaultLibrary(device)
    pipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "GUIRenderer",
      vertexFunction: try MetalUtil.loadFunction("guiVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("guiFragment", from: library),
      blendingEnabled: false
    )

    scale = 5

    gui = GUI(client: client)
  }

  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Construct uniforms
    let drawableSize = view.drawableSize
    let drawableWidth = Float(drawableSize.width)
    let drawableHeight = Float(drawableSize.height)
    let width = drawableWidth
    let height = drawableHeight
    let screenSpaceToNormalized = matrix_float3x3([
        [2 / width, 0, -1],
        [0, -2 / height, 1],
        [0, 0, 1]
    ])

    let transformation = screenSpaceToNormalized
    var uniforms = GUIUniforms(screenSpaceToNormalized: transformation, scale: scale)
    uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)

    // Set vertex buffers
    encoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)

    // Set pipeline
    encoder.setRenderPipelineState(pipelineState)

    // Render meshes
    let meshes = try gui.meshes(
      device: device,
      scale: scale,
      effectiveDrawableSize: [drawableWidth / scale, drawableHeight / scale]
    )

    for mesh in meshes {
      try mesh.render(into: encoder, with: device, quadIndexBuffer: quadIndexBuffer)
    }
  }
}
