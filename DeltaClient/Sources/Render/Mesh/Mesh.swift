//
//  Mesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import simd
import os

protocol Mesh {
  associatedtype Uniforms
  
  var queue: DispatchQueue { get set }
  
  var vertices: [Vertex] { get set }
  var indices: [UInt32] { get set }
  var uniforms: Uniforms! { get set }

  var vertexBuffer: MTLBuffer! { get set }
  var indexBuffer: MTLBuffer! { get set }
  var uniformBuffer: MTLBuffer! { get set }
  
  var hasChanged: Bool { get set }
}

extension Mesh {
  var isEmpty: Bool {
    queue.sync {
      return vertices.isEmpty
    }
  }
  
  mutating func createBuffers(device: MTLDevice) -> (vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, uniformBuffer: MTLBuffer) {
    queue.sync {
      if hasChanged { // only remake the buffers if something has been changed
        Logger.debug("regenerating chunk mesh buffers")
        
        let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [.storageModeShared])!
        vertexBuffer.label = "vertexBuffer"
        
        let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
        indexBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [.storageModeShared])!
        indexBuffer.label = "indexBuffer"
        
        // TODO: have separate hasChanged for uniforms (they change a lot less often for chunks)
        // TODO: reuse buffer for uniforms (they have a fixed size)
        let uniformBufferSize = MemoryLayout<Uniforms>.stride
        uniformBuffer = device.makeBuffer(bytes: &uniforms, length: uniformBufferSize, options: [.storageModeShared])!
        uniformBuffer.label = "uniformBuffer"
        
        hasChanged = false
      }
    }
    
    return (
      vertexBuffer: vertexBuffer,
      indexBuffer: indexBuffer,
      uniformBuffer: uniformBuffer
    )
  }
}
