//
//  Mesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import Metal
import simd

enum MeshError: LocalizedError {
  case failedToCreateBuffer
}

protocol Mesh {
  var vertices: [Vertex] { get set }
  var indices: [UInt32] { get set }
  var uniforms: Uniforms { get set }

  var vertexBuffer: MTLBuffer! { get set }
  var indexBuffer: MTLBuffer! { get set }
  var uniformBuffer: MTLBuffer! { get set }
  
  var hasChanged: Bool { get set }
}

extension Mesh {
  var isEmpty: Bool {
    return vertices.isEmpty
  }
  
  func createIndexBuffer(device: MTLDevice) throws -> MTLBuffer {
    let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
    guard let buffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "indexBuffer"
    return buffer
  }
  
  func createVertexBuffer(device: MTLDevice) throws -> MTLBuffer {
    let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
    guard let buffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "vertexBuffer"
    return buffer
  }
  
  func createUniformBuffer(device: MTLDevice) throws -> MTLBuffer {
    var uniforms = self.uniforms // mutable copy
    let uniformBufferSize = MemoryLayout<Uniforms>.stride
    guard let buffer = device.makeBuffer(bytes: &uniforms, length: uniformBufferSize, options: [.storageModeShared]) else {
      throw MeshError.failedToCreateBuffer
    }
    buffer.label = "uniformBuffer"
    return buffer
  }
  
  mutating func createBuffers(device: MTLDevice) throws -> MeshBuffers {
    // only remake the buffers if something has been changed
    if hasChanged {
      // TODO: have separate hasChanged for uniforms (they change a lot less often for chunks)
      // TODO: reuse buffer for uniforms (they have a fixed size)
      vertexBuffer = try createVertexBuffer(device: device)
      indexBuffer = try createIndexBuffer(device: device)
      uniformBuffer = try createUniformBuffer(device: device)
      
      hasChanged = false
    }
    
    return MeshBuffers(
      vertexBuffer: vertexBuffer,
      indexBuffer: indexBuffer,
      uniformBuffer: uniformBuffer
    )
  }
}
