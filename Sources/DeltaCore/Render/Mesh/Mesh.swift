import Foundation
import Metal

public enum MeshError: LocalizedError {
  case failedToCreateBuffer
}

/// Holds and renders geometry data.
public struct Mesh {
  /// The vertices in the mesh.
  public var vertices: [Vertex] = []
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
  
  /// `true` if the mesh contains no geometry.
  public var isEmpty: Bool {
    return vertices.isEmpty || indices.isEmpty
  }
  
  /// Encodes the draw commands to render this mesh into a render encoder.
  /// - Parameters:
  ///   - encoder: Render encode to encode commands into.
  ///   - device: Device to use.
  ///   - commandQueue: Command queue used to create buffers if not created already.
  public mutating func render(into encoder: MTLRenderCommandEncoder, with device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    let vertexBuffer = try (self.vertexBuffer ?? Self.createPrivateBuffer(
      labelled: "vertexBuffer",
      containing: vertices,
      device: device,
      commandQueue: commandQueue))
    
    let indexBuffer = try (self.indexBuffer ?? Self.createPrivateBuffer(
      labelled: "indexBuffer",
      containing: indices,
      device: device,
      commandQueue: commandQueue))
    
    let uniformsBuffer = try (self.uniformsBuffer ?? Self.createPrivateBuffer(
      labelled: "uniformsBuffer",
      containing: [uniforms],
      device: device,
      commandQueue: commandQueue))
    
    if self.vertexBuffer == nil {
      self.vertexBuffer = vertexBuffer
    }
    
    if self.indexBuffer == nil {
      self.indexBuffer = indexBuffer
    }
    
    if self.uniformsBuffer == nil {
      self.uniformsBuffer = uniformsBuffer
    }
    
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: indexBuffer.length / 4,
      indexType: .uint32,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0)
  }
  
  /// Force buffers to be recreated on next call to ``render(into:for:commandQueue:)``.
  /// - Parameters:
  ///   - keepVertexBuffer: If `true`, the vertex buffer is not invalidated.
  ///   - keepIndexBuffer: If `true`, the index buffer is not invalidated.
  ///   - keepUniformsBuffer: If `true`, the uniforms buffer is not invalidated.
  public mutating func invalidateBuffers(keepVertexBuffer: Bool = false, keepIndexBuffer: Bool = false, keepUniformsBuffer: Bool = false) {
    if !keepVertexBuffer {
      vertexBuffer = nil
    }
    if !keepIndexBuffer {
      indexBuffer = nil
    }
    if !keepUniformsBuffer {
      uniformsBuffer = nil
    }
  }
  
  /// Creates a buffer on the GPU containing a given array.
  /// - Returns: A new private buffer.
  private static func createPrivateBuffer<T>(labelled label: String = "buffer", containing items: [T], device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MTLBuffer {
    // First copy the array to a scratch buffer (accessible from both CPU and GPU)
    let bufferSize = MemoryLayout<T>.stride * items.count
    guard let sharedBuffer = device.makeBuffer(bytes: items, length: bufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    
    // Create a private buffer (only accessible from GPU)
    guard let privateBuffer = device.makeBuffer(length: bufferSize, options: [.storageModePrivate]) else {
      throw MeshError.failedToCreateBuffer
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
