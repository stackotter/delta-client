import Foundation
import Metal

public enum MeshError: LocalizedError {
  case failedToCreateBuffer
}

public class Mesh {
  /// The mesh's vertex data
  public var vertices: [Vertex] = []
  /// The mesh's winding
  public var indices: [UInt32] = []
  /// Holds the section's model to world transformation matrix
  public var uniforms = Uniforms()
  
  /// A cache of the mesh's buffers
  private var buffers: MeshBuffers?
  
  /// Whether the mesh contains any geometry or not
  public final var isEmpty: Bool {
    return vertices.isEmpty || indices.isEmpty
  }
  
  /**
   Gets the vertex, index and uniforms buffers for the mesh.
   
   If the buffers are not yet generated they will be created and populated with the mesh's
   current geometry. Otherwise, they are just returned from the private cache variable.
   
   - Parameter device: `MTLDevice` to create the buffers on.
   - Returns: Three MTLBuffer's; a vertex buffer, an index buffer and a uniforms buffer.
   */
  public final func getBuffers(for device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MeshBuffers {
    if let buffers = buffers {
      return buffers
    }
    
    let vertexBuffer = try createVertexBuffer(device: device, commandQueue: commandQueue)
    let indexBuffer = try createIndexBuffer(device: device, commandQueue: commandQueue)
    let uniformsBuffer = try createUniformsBuffer(device: device, commandQueue: commandQueue)
    
    let buffers = MeshBuffers(
      vertexBuffer: vertexBuffer,
      indexBuffer: indexBuffer,
      uniformsBuffer: uniformsBuffer)
    self.buffers = buffers
    return buffers
  }
  
  /// Removes the cached buffers and forces them to be recreated next time they are requested.
  public final func clearBufferCache() {
    buffers = nil
  }
  
  private final func createIndexBuffer(device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MTLBuffer {
    let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
    guard let sharedBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    
    guard let buffer = device.makeBuffer(length: indexBufferSize, options: [.storageModePrivate]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "indexBuffer"
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw MeshError.failedToCreateBuffer
    }
    
    encoder.copy(from: sharedBuffer, sourceOffset: 0, to: buffer, destinationOffset: 0, size: indexBufferSize)
    encoder.endEncoding()
    commandBuffer.commit()
    
    return buffer
  }
  
  private final func createVertexBuffer(device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MTLBuffer {
    let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
    guard let sharedBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    
    guard let buffer = device.makeBuffer(length: vertexBufferSize, options: [.storageModePrivate]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "vertexBuffer"
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw MeshError.failedToCreateBuffer
    }
    
    encoder.copy(from: sharedBuffer, sourceOffset: 0, to: buffer, destinationOffset: 0, size: vertexBufferSize)
    encoder.endEncoding()
    commandBuffer.commit()
    
    return buffer
  }
  
  private final func createUniformsBuffer(device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MTLBuffer {
    let uniformBufferSize = MemoryLayout<Uniforms>.stride
    guard let sharedBuffer = device.makeBuffer(bytes: &uniforms, length: uniformBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    
    guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [.storageModePrivate]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "uniformsBuffer"
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw MeshError.failedToCreateBuffer
    }
    
    encoder.copy(from: sharedBuffer, sourceOffset: 0, to: buffer, destinationOffset: 0, size: uniformBufferSize)
    encoder.endEncoding()
    commandBuffer.commit()
    
    return buffer
  }
}
