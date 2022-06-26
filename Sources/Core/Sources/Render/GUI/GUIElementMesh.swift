import MetalKit

/// A generic texture-backed GUI element.
struct GUIElementMesh {
  /// The element's position.
  var position: SIMD2<Float>
  /// The quads making up the element.
  var quads: [GUIQuadInstance]
  /// The mesh's uniforms.
  var uniformsBuffer: MTLBuffer
  /// The array texture used to render this element.
  var arrayTexture: MTLTexture
  /// The buffer containing ``quads``.
  var buffer: MTLBuffer
  /// The unscaled width.
  var width: Float
  /// The unscaled height.
  var height: Float

  /// Creates a mesh from some text and a font.
  init(text: String, font: Font, device: MTLDevice) throws {
    guard !text.isEmpty else {
      throw GUIRendererError.emptyText
    }

    arrayTexture = try font.createArrayTexture(device)

    quads = []

    var currentX: Float = 0
    let currentY: Float = 0
    let spacing: Float = 1
    for character in text {
      var quad = try GUIQuadInstance(
        for: character,
        with: font,
        fontArrayTexture: arrayTexture
      )
      quad.translate(amount: [
        currentX,
        currentY
      ])
      quads.append(quad)
      currentX += quad.size.x + spacing
    }

    width = currentX - spacing
    height = Float(Font.defaultCharacterHeight)

    buffer = try MetalUtil.makeBuffer(
      device,
      bytes: &quads,
      length: MemoryLayout<GUIQuadInstance>.stride * quads.count,
      options: []
    )

    uniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<GUIElementUniforms>.stride,
      options: []
    )

    position = .zero
  }

  /// Renders the text. Expects ``GUIQuadGeometry/vertices`` to be bound at vertex buffer index 0 and
  /// ``GUIUniforms`` to be bound at vertex buffer index 1. Also expects pipeline state to be set to
  /// ``GUIRenderer/pipelineState``.
  func render(
    into encoder: MTLRenderCommandEncoder,
    with device: MTLDevice,
    quadIndexBuffer: MTLBuffer
  ) throws {
    var uniforms = GUIElementUniforms(position: position)
    uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<GUIElementUniforms>.stride)

    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
    encoder.setVertexBuffer(buffer, offset: 0, index: 3)
    encoder.setFragmentTexture(arrayTexture, index: 0)
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: GUIQuadGeometry.indices.count,
      indexType: .uint16,
      indexBuffer: quadIndexBuffer,
      indexBufferOffset: 0,
      instanceCount: quads.count
    )
  }
}
