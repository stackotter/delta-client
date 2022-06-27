import MetalKit

/// A generic texture-backed GUI element.
struct GUIElementMesh {
  /// The element's position.
  var position: SIMD2<Float> = .zero
  /// The quads making up the element.
  var quads: [GUIQuadInstance] = []
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
  init(
    text: String,
    font: Font,
    fontArrayTexture: MTLTexture,
    device: MTLDevice
  ) throws {
    guard !text.isEmpty else {
      throw GUIRendererError.emptyText
    }

    arrayTexture = fontArrayTexture

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

    (buffer, uniformsBuffer) = try Self.createBuffers(quads: &quads, device: device)
  }

  init(
    sprite: GUISpriteDescriptor,
    guiTexturePalette: GUITexturePalette,
    guiArrayTexture: MTLTexture,
    device: MTLDevice
  ) throws {
    arrayTexture = guiArrayTexture

    width = Float(sprite.size.x)
    height = Float(sprite.size.y)

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

    (buffer, uniformsBuffer) = try Self.createBuffers(quads: &quads, device: device)
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
