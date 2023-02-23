import Foundation
import Metal

public enum MeshError: LocalizedError {
  case failedToCreateBuffer

  public var errorDescription: String? {
    switch self {
      case .failedToCreateBuffer:
        return "Failed to create buffer."
    }
  }
}

/// Holds and renders geometry data.
public struct Mesh {
  /// The vertices in the mesh.
  public var vertices: [BlockVertex] = []
  /// The vertex windings.
  public var indices: [UInt32] = []
  /// The mesh's model to world transformation matrix.
  public var uniforms = Uniforms()

  /// A GPU buffer containing the vertices.
  public var vertexBuffer: MTLBuffer?
  /// A GPU buffer containing the vertex windings.
  public var indexBuffer: MTLBuffer?
  /// A GPU buffer containing the model to world transformation matrix.
  public var uniformsBuffer: MTLBuffer?

  /// If `false`, ``vertexBuffer`` will be recreated next time ``render(into:with:commandQueue:)`` is called.
  public var vertexBufferIsValid = false
  /// If `false`, ``indexBuffer`` will be recreated next time ``render(into:with:commandQueue:)`` is called.
  public var indexBufferIsValid = false
  /// If `false`, ``uniformsBuffer`` will be recreated next time ``render(into:with:commandQueue:)`` is called.
  public var uniformsBufferIsValid = false

  /// `true` if the mesh contains no geometry.
  public var isEmpty: Bool {
    return vertices.isEmpty || indices.isEmpty
  }

  /// Create a new empty mesh.
  public init() {}

  /// Create a new populated mesh.
  public init(vertices: [BlockVertex], indices: [UInt32], uniforms: Uniforms) {
    self.vertices = vertices
    self.indices = indices
    self.uniforms = uniforms
  }

  /// Create a new mesh with geometry.
  public init(_ geometry: Geometry, uniforms: Uniforms) {
    self.init(vertices: geometry.vertices, indices: geometry.indices, uniforms: uniforms)
  }

  /// Encodes the draw commands to render this mesh into a render encoder. Creates buffers if necessary.
  /// - Parameters:
  ///   - encoder: Render encode to encode commands into.
  ///   - device: Device to use.
  ///   - commandQueue: Command queue used to create buffers if not created already.
  public mutating func render(
    into encoder: MTLRenderCommandEncoder,
    with device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    if isEmpty {
      return
    }
    // Get buffers. If the buffer is valid and not nil, it is used. If the buffer is invalid and not nil,
    // it is repopulated with the new data (if big enough, otherwise a new buffer is created). If the
    // buffer is nil, a new one is created.
    let vertexBuffer = try ((vertexBufferIsValid ? vertexBuffer : nil) ?? MetalUtil.createPrivateBuffer(
      labelled: "vertexBuffer",
      containing: vertices,
      reusing: vertexBuffer,
      device: device,
      commandQueue: commandQueue
    ))

    let indexBuffer = try ((indexBufferIsValid ? indexBuffer : nil) ?? MetalUtil.createPrivateBuffer(
      labelled: "indexBuffer",
      containing: indices,
      reusing: indexBuffer,
      device: device,
      commandQueue: commandQueue
    ))

    let uniformsBuffer = try ((uniformsBufferIsValid ? uniformsBuffer : nil) ?? MetalUtil.createPrivateBuffer(
      labelled: "uniformsBuffer",
      containing: [uniforms],
      reusing: uniformsBuffer,
      device: device,
      commandQueue: commandQueue
    ))

    // Update cached buffers. Unnecessary assignments won't affect performance because `MTLBuffer`s
    // are just descriptors, not the actual data
    self.vertexBuffer = vertexBuffer
    self.indexBuffer = indexBuffer
    self.uniformsBuffer = uniformsBuffer

    // Buffers are now all valid
    vertexBufferIsValid = true
    indexBufferIsValid = true
    uniformsBufferIsValid = true

    // Encode draw call
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: indices.count,
      indexType: .uint32,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0
    )
  }

  /// Force buffers to be recreated on next call to ``render(into:for:commandQueue:)``.
  ///
  /// The underlying private buffer may be reused, but it will be repopulated with the new data.
  ///
  /// - Parameters:
  ///   - keepVertexBuffer: If `true`, the vertex buffer is not invalidated.
  ///   - keepIndexBuffer: If `true`, the index buffer is not invalidated.
  ///   - keepUniformsBuffer: If `true`, the uniforms buffer is not invalidated.
  public mutating func invalidateBuffers(keepVertexBuffer: Bool = false, keepIndexBuffer: Bool = false, keepUniformsBuffer: Bool = false) {
    vertexBufferIsValid = keepVertexBuffer
    indexBufferIsValid = keepIndexBuffer
    uniformsBufferIsValid = keepUniformsBuffer
  }

  /// Clears the mesh's geometry and invalidates its buffers.
  public mutating func clearGeometry() {
    vertices = []
    indices = []
    invalidateBuffers(keepUniformsBuffer: true)
  }
}
