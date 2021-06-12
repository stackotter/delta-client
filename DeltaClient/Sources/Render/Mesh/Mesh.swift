//
//  Mesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import Metal

enum MeshError: LocalizedError {
  case failedToCreateBuffer
}

class Mesh {
  /// The mesh's vertex data
  var vertices: [Vertex] = []
  /// The mesh's winding
  var indices: [UInt32] = []
  /// Holds the section's model to world transformation matrix
  var uniforms = Uniforms()
  
  /// A cache of the mesh's buffers
  private var buffers: MeshBuffers?
  
  /// Whether the mesh contains any geometry or not
  var isEmpty: Bool {
    return vertices.isEmpty || indices.isEmpty
  }
  
  /**
   Gets the vertex, index and uniforms buffers for the mesh.
   
   If the buffers are not yet generated they will be created and populated with the mesh's
   current geometry. Otherwise, they are just returned from the private cache variable.
   
   - Parameter device: `MTLDevice` to create the buffers on.
   - Returns: Three MTLBuffer's; a vertex buffer, an index buffer and a uniforms buffer.
   */
  func getBuffers(for device: MTLDevice) throws -> MeshBuffers {
    if let buffers = buffers {
      return buffers
    }
    
    let vertexBuffer = try createVertexBuffer(device: device)
    let indexBuffer = try createIndexBuffer(device: device)
    let uniformsBuffer = try createUniformsBuffer(device: device)
    
    let buffers = MeshBuffers(
      vertexBuffer: vertexBuffer,
      indexBuffer: indexBuffer,
      uniformsBuffer: uniformsBuffer)
    self.buffers = buffers
    return buffers
  }
  
  /// Removes the cached buffers and forces them to be recreated next time they are requested.
  func clearBufferCache() {
    buffers = nil
  }
  
  private func createIndexBuffer(device: MTLDevice) throws -> MTLBuffer {
    let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
    guard let buffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "indexBuffer"
    return buffer
  }
  
  private func createVertexBuffer(device: MTLDevice) throws -> MTLBuffer {
    let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
    guard let buffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "vertexBuffer"
    return buffer
  }
  
  private func createUniformsBuffer(device: MTLDevice) throws -> MTLBuffer {
    let uniformBufferSize = MemoryLayout<Uniforms>.stride
    guard let buffer = device.makeBuffer(bytes: &uniforms, length: uniformBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "uniformsBuffer"
    return buffer
  }
}
