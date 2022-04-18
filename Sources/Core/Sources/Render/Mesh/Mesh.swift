import Foundation
import Metal

public enum MeshError: LocalizedError {
  case failedToCreateBuffer
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
    
//    var stopwatch = Stopwatch(mode: .verbose, name: "Mesh.render")
    
//    stopwatch.startMeasurement("vertexBuffer")
    // Get buffers. If the buffer is valid and not nil, it is used. If the buffer is invalid and not nil,
    // it is repopulated with the new data (if big enough, otherwise a new buffer is created). If the
    // buffer is nil, a new one is created.
    let vertexBuffer = try ((vertexBufferIsValid ? vertexBuffer : nil) ?? Self.createPrivateBuffer(
      labelled: "vertexBuffer",
      containing: vertices,
      reusing: vertexBuffer,
      device: device,
      commandQueue: commandQueue))
//    stopwatch.stopMeasurement("vertexBuffer")
    
//    stopwatch.startMeasurement("indexBuffer")
    let indexBuffer = try ((indexBufferIsValid ? indexBuffer : nil) ?? Self.createPrivateBuffer(
      labelled: "indexBuffer",
      containing: indices,
      reusing: indexBuffer,
      device: device,
      commandQueue: commandQueue))
//    stopwatch.stopMeasurement("indexBuffer")
    
//    stopwatch.startMeasurement("uniformsBuffer")
    let uniformsBuffer = try ((uniformsBufferIsValid ? uniformsBuffer : nil) ?? Self.createPrivateBuffer(
      labelled: "uniformsBuffer",
      containing: [uniforms],
      reusing: uniformsBuffer,
      device: device,
      commandQueue: commandQueue))
//    stopwatch.stopMeasurement("uniformsBuffer")
    
//    stopwatch.startMeasurement("update caches")
    // Update cached buffers. Unnecessary assignments won't affect performance because `MTLBuffer`s are just descriptors, not the actual data
    self.vertexBuffer = vertexBuffer
    self.indexBuffer = indexBuffer
    self.uniformsBuffer = uniformsBuffer
//    stopwatch.stopMeasurement("update caches")
    
    // Buffers are now all valid
    vertexBufferIsValid = true
    indexBufferIsValid = true
    uniformsBufferIsValid = true
    
//    stopwatch.startMeasurement("setVertexBuffer calls")
    // Encode draw call
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
//    stopwatch.stopMeasurement("setVertexBuffer calls")
    
//    stopwatch.startMeasurement("drawIndexedPrimitives")
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: indices.count,
      indexType: .uint32,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0)
//    stopwatch.stopMeasurement("drawIndexedPrimitives")
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
  
  /// Creates a buffer on the GPU containing a given array. Reuses the supplied private buffer if it's big enough.
  /// - Returns: A new private buffer.
  private static func createPrivateBuffer<T>(
    labelled label: String = "buffer",
    containing items: [T],
    reusing existingBuffer: MTLBuffer? = nil,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws -> MTLBuffer {
    // First copy the array to a scratch buffer (accessible from both CPU and GPU)
    let bufferSize = MemoryLayout<T>.stride * items.count
    guard let sharedBuffer = device.makeBuffer(bytes: items, length: bufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    
    // Create a private buffer (only accessible from GPU) or reuse the existing buffer if possible
    let privateBuffer: MTLBuffer
    if let existingBuffer = existingBuffer, existingBuffer.length >= bufferSize {
//      log.trace("Reusing existing metal \(label)")
      privateBuffer = existingBuffer
    } else {
//      log.trace("Creating new metal \(label)")
      guard let buffer = device.makeBuffer(length: bufferSize, options: [.storageModePrivate]) else {
        throw MeshError.failedToCreateBuffer
      }
      privateBuffer = buffer
    }
    privateBuffer.label = label
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw MeshError.failedToCreateBuffer
    }
    
    // Encode and commit a blit operation to copy the contents of the scratch buffer into the private buffer
    encoder.copy(from: sharedBuffer, sourceOffset: 0, to: privateBuffer, destinationOffset: 0, size: bufferSize)
    encoder.endEncoding()
    commandBuffer.commit()
    
    return privateBuffer
  }
}
