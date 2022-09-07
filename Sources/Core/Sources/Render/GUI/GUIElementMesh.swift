import MetalKit

/// A generic texture-backed GUI element.
struct GUIElementMesh {
  /// The amount of extra room to allocate when creating a vertex buffer to avoid needing to create
  /// a new one too soon. Currently set to leave enough room for 20 extra quads. This measurably
  /// cuts down the number of new vertex buffers created.
  private static let vertexBufferHeadroom = 80 * MemoryLayout<GUIVertex>.stride

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

  /// The minimum size that the vertex buffer must be.
  var requiredVertexBufferSize: Int {
    return vertices.count * MemoryLayout<GUIVertex>.stride
  }


  /// Creates a mesh from a collection of quads.
  init(size: SIMD2<Int>, arrayTexture: MTLTexture?, quads: [GUIQuad]) {
    self.size = size
    self.arrayTexture = arrayTexture

    // Basically just a fancy flat map (it's measurably faster than using flatmap in this case and
    // this is performance critical, otherwise I would never use this code)
    let vertexCount = quads.count * 4
    vertices = Array(unsafeUninitializedCapacity: vertexCount) { buffer, count in
      for i in 0..<quads.count {
        let quadVertices = quads[i].toVertices()
        let base = i * 4
        quadVertices.withUnsafeBufferPointer { quadBuffer in
          // You're welcome for the beautiful alignment, if only base were a one letter variable, it
          // could be even nicer...
          buffer[  base  ] = quadBuffer[0]
          buffer[base + 1] = quadBuffer[1]
          buffer[base + 2] = quadBuffer[2]
          buffer[base + 3] = quadBuffer[3]
        }
      }

      count = vertexCount
    }
  }

  /// Creates a mesh from a collection of vertices.
  init(size: SIMD2<Int>, arrayTexture: MTLTexture, vertices: [GUIVertex]) {
    self.size = size
    self.arrayTexture = arrayTexture
    self.vertices = vertices
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
    if let vertexBufferTemp = self.vertexBuffer {
      vertexBuffer = vertexBufferTemp
    } else {
      vertexBuffer = try MetalUtil.makeBuffer(
        device,
        length: requiredVertexBufferSize + Self.vertexBufferHeadroom,
        options: []
      )
      self.vertexBuffer = vertexBuffer
    }

    let uniformsBuffer: MTLBuffer
    var uniforms = GUIElementUniforms(position: SIMD2(position))
    if let uniformsBufferTemp = self.uniformsBuffer {
      uniformsBuffer = uniformsBufferTemp
    } else {
      uniformsBuffer = try MetalUtil.makeBuffer(
        device,
        length: MemoryLayout<GUIElementUniforms>.stride,
        options: []
      )
      self.uniformsBuffer = uniformsBuffer
    }

    // Assume that the buffers are outdated
    vertexBuffer.contents().copyMemory(
      from: &vertices,
      byteCount: requiredVertexBufferSize
    )
    uniformsBuffer.contents().copyMemory(
      from: &uniforms,
      byteCount: MemoryLayout<GUIElementUniforms>.stride
    )

    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
    encoder.setFragmentTexture(arrayTexture, index: 0)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 4 * 6)
  }
}
