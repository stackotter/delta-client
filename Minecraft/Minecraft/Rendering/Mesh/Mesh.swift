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
  
  var isEmpty: Bool {
    return vertices.count == 0
  }
  
  var numIndices: Int {
    var num = 0
    queue.sync {
      num = indices.count
    }
    return num
  }
  
  init() {
    self.queue = DispatchQueue(label: "mesh")
  }
  
  func createVertexBuffer(for device: MTLDevice) -> MTLBuffer {
    var buffer: MTLBuffer!
    queue.sync {
      let bufferSize = MemoryLayout<Vertex>.stride * vertices.count
      buffer = device.makeBuffer(bytes: vertices, length: bufferSize, options: [])!
      buffer.label = "vertexBuffer"
    }
    return buffer
  }
  
  func createIndexBuffer(for device: MTLDevice) -> MTLBuffer {
    var buffer: MTLBuffer!
    queue.sync {
      let bufferSize = MemoryLayout<UInt32>.stride * indices.count
      buffer = device.makeBuffer(bytes: indices, length: bufferSize, options: [])!
      buffer.label = "indexBuffer"
    }
    return buffer
  }
}
