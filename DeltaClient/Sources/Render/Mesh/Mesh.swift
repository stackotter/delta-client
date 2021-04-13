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

class Mesh {
  var hasChanged = false
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var queue: DispatchQueue
  
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  
  var isEmpty: Bool {
    return vertices.count == 0
  }
  
  init() {
    self.queue = DispatchQueue(label: "mesh")
  }
  
  func createBuffers(device: MTLDevice) -> (vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer) {
    queue.sync {
      if hasChanged { // only remake the buffers if something has been changed
        Logger.debug("regenerating chunk mesh buffers")
        
        let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [])!
        vertexBuffer.label = "vertexBuffer"
        
        let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
        indexBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [])!
        indexBuffer.label = "indexBuffer"
        
        hasChanged = false
      }
    }
    return (vertexBuffer: vertexBuffer, indexBuffer: indexBuffer)
  }
}
