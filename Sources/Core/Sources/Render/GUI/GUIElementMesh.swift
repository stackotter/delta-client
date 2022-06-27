import MetalKit

/// A generic texture-backed GUI element.
struct GUIElementMesh {
  /// The element's position.
  var position: SIMD2<Int> = .zero
  /// The unscaled size.
  var size: SIMD2<Int>
  /// The quads making up the element.
  var quads: [GUIQuadInstance] = []
  /// The mesh's uniforms.
  var uniformsBuffer: MTLBuffer?
  /// The array texture used to render this element.
  var arrayTexture: MTLTexture
  /// The buffer containing ``quads``.
  var buffer: MTLBuffer?

  /// Creates a mesh from some text and a font.
  init(
    text: String,
    font: Font,
    fontArrayTexture: MTLTexture
  ) throws {
    guard !text.isEmpty else {
      throw GUIRendererError.emptyText
    }

    arrayTexture = fontArrayTexture

    var currentX = 0
    let currentY = 0
    let spacing = 1
    for character in text {
      var quad = try GUIQuadInstance(
        for: character,
        with: font,
        fontArrayTexture: arrayTexture
      )
      quad.translate(amount: SIMD2([
        currentX,
        currentY
      ]))
      quads.append(quad)
      currentX += Int(quad.size.x) + spacing
    }

    let width = currentX - spacing
    let height = Font.defaultCharacterHeight
    size = [width, height]
  }

  init(
    sprite: GUISpriteDescriptor,
    guiTexturePalette: GUITexturePalette,
    guiArrayTexture: MTLTexture
  ) throws {
    arrayTexture = guiArrayTexture

    let textureSize: SIMD2 = [
      Float(guiArrayTexture.width),
      Float(guiArrayTexture.height)
    ]

    quads = [GUIQuadInstance(
      position: [0, 0],
      size: SIMD2<Float>(sprite.size),
      uvMin: SIMD2<Float>(sprite.position) / textureSize,
      uvSize: SIMD2<Float>(sprite.size) / textureSize,
      textureIndex: UInt8(guiTexturePalette.textureIndex(for: sprite.slice))
    )]

    let width = sprite.size.x
    let height = sprite.size.y
    size = [width, height]
  }

  static func createBuffers(
    quads: inout [GUIQuadInstance],
    device: MTLDevice
  ) throws -> (quads: MTLBuffer, uniforms: MTLBuffer) {
    let buffer = try MetalUtil.makeBuffer(
      device,
      bytes: &quads,
      length: MemoryLayout<GUIQuadInstance>.stride * quads.count,
      options: []
    )

    let uniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<GUIElementUniforms>.stride,
      options: []
    )

    return (quads: buffer, uniforms: uniformsBuffer)
  }

  /// Renders the text. Expects ``GUIQuadGeometry/vertices`` to be bound at vertex buffer index 0 and
  /// ``GUIUniforms`` to be bound at vertex buffer index 1. Also expects pipeline state to be set to
  /// ``GUIRenderer/pipelineState``.
  mutating func render(
    into encoder: MTLRenderCommandEncoder,
    with device: MTLDevice,
    quadIndexBuffer: MTLBuffer
  ) throws {
    // Create buffers if necesary
    let buffer: MTLBuffer
    let uniformsBuffer: MTLBuffer
    if let bufferTemp = self.buffer, let uniformsBufferTemp = self.uniformsBuffer {
      buffer = bufferTemp
      uniformsBuffer = uniformsBufferTemp
    } else {
      (buffer, uniformsBuffer) = try Self.createBuffers(quads: &quads, device: device)
    }

    // Update uniforms
    var uniforms = GUIElementUniforms(position: SIMD2(position))
    uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<GUIElementUniforms>.stride)

    // Render instanced quads
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
