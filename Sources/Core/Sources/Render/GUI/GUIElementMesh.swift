import MetalKit

/// A generic texture-backed GUI element.
struct GUIElementMesh {
  /// The element's position.
  var position: SIMD2<Int> = .zero
  /// The unscaled size.
  var size: SIMD2<Int>
  /// The vertices making up the element.
  var vertices: [GUIVertex]
  /// The array texture used to render this element.
  var arrayTexture: MTLTexture?

  /// The buffer containing ``vertices``.
  var vertexBuffer: MTLBuffer?
  /// The mesh's uniforms.
  var uniformsBuffer: MTLBuffer?

  /// Creates a mesh from a collection of quads.
  init(size: SIMD2<Int>, arrayTexture: MTLTexture?, quads: [GUIQuad]) {
    self.size = size
    self.arrayTexture = arrayTexture
    vertices = quads.flatMap { quad in
      return quad.toVertices()
    }
  }

  /// Creates a mesh from a collection of vertices.
  init(size: SIMD2<Int>, arrayTexture: MTLTexture, vertices: [GUIVertex]) {
    self.size = size
    self.arrayTexture = arrayTexture
    self.vertices = vertices
  }

  /// Creates a mesh from some text and a font.
  init(
    text: String,
    font: Font,
    fontArrayTexture: MTLTexture,
    color: SIMD4<Float> = [1, 1, 1, 1],
    outlineColor: SIMD4<Float>? = nil
  ) throws {
    var currentX = 0
    let currentY = 0
    let spacing = 1
    var quads: [GUIQuad] = []
    for character in text {
      guard var quad = try? GUIQuad(
        for: character,
        with: font,
        fontArrayTexture: fontArrayTexture,
        tint: color
      ) else {
        continue
      }

      quad.translate(amount: SIMD2([
        currentX,
        currentY
      ]))
      quads.append(quad)
      currentX += Int(quad.size.x) + spacing
    }

    guard !quads.isEmpty else {
      throw GUIRendererError.emptyText
    }

    // Create outline
    if let outlineColor = outlineColor {
      var outlineQuads: [GUIQuad] = []
      let outlineTranslations: [SIMD2<Float>] = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]

      for translation in outlineTranslations {
        for var quad in quads {
          quad.translate(amount: translation)
          quad.tint = outlineColor
          outlineQuads.append(quad)
        }
      }

      // Outline is rendered before the actual text
      quads = outlineQuads + quads
    }

    let width = currentX - spacing
    let height = Font.defaultCharacterHeight
    self.init(size: [width, height], arrayTexture: fontArrayTexture, quads: quads)
  }

  /// Creates a mesh that displays the specified gui sprite.
  init(
    sprite: GUISpriteDescriptor,
    guiTexturePalette: GUITexturePalette,
    guiArrayTexture: MTLTexture
  ) throws {
     self.init(
      size: sprite.size,
      arrayTexture: guiArrayTexture,
      quads: [GUIQuad(
        for: sprite,
        guiTexturePalette: guiTexturePalette,
        guiArrayTexture: guiArrayTexture
      )]
    )
  }

  /// Creates a mesh that displays a single slice of a texture.
  init(
    slice: Int,
    texture: MTLTexture
  ) {
    self.init(
      size: [16, 16],
      arrayTexture: texture,
      quads: [GUIQuad(
        position: [0, 0],
        size: [16, 16],
        uvMin: [0, 0],
        uvSize: [1, 1],
        textureIndex: UInt16(slice)
      )]
    )
  }

  static func createBuffers(
    vertices: inout [GUIVertex],
    uniforms: inout GUIElementUniforms,
    device: MTLDevice
  ) throws -> (vertexBuffer: MTLBuffer, uniformsBuffer: MTLBuffer) {
    let vertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &vertices,
      length: MemoryLayout<GUIVertex>.stride * vertices.count,
      options: []
    )

    let uniformsBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &uniforms,
      length: MemoryLayout<GUIElementUniforms>.stride,
      options: []
    )

    return (vertexBuffer: vertexBuffer, uniformsBuffer: uniformsBuffer)
  }

  /// Renders the mesh. Expects ``GUIUniforms`` to be bound at vertex buffer index 1. Also expects
  /// pipeline state to be set to ``GUIRenderer/pipelineState``.
  mutating func render(
    into encoder: MTLRenderCommandEncoder,
    with device: MTLDevice
  ) throws {
    // Avoid rendering empty mesh
    if vertices.isEmpty {
      return
    }

    let vertexBuffer: MTLBuffer
    let uniformsBuffer: MTLBuffer
    if let vertexBufferTemp = self.vertexBuffer, let uniformsBufferTemp = self.uniformsBuffer {
      vertexBuffer = vertexBufferTemp
      uniformsBuffer = uniformsBufferTemp
    } else {
      var uniforms = GUIElementUniforms(position: SIMD2(position))
      (vertexBuffer, uniformsBuffer) = try Self.createBuffers(
        vertices: &vertices,
        uniforms: &uniforms,
        device: device
      )
    }

    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
    encoder.setFragmentTexture(arrayTexture, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 4 * 6)
  }
}
