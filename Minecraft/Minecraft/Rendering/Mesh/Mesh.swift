//
//  MeshObject.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import simd

class Mesh {
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var queue: DispatchQueue
  
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  
  var numIndices = 0
  
  var isEmpty: Bool {
    return vertices.count == 0
  }
  
  init() {
    self.queue = DispatchQueue(label: "mesh")
  }
  
  func createBuffers(device: MTLDevice) {
    queue.sync {
      let vertexBufferSize = MemoryLayout<Vertex>.stride * vertices.count
      vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: [])!
      vertexBuffer.label = "vertexBuffer"
      
      let indexBufferSize = MemoryLayout<UInt32>.stride * indices.count
      indexBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: [])!
      indexBuffer.label = "indexBuffer"
      
      numIndices = indices.count
    }
  }
}
