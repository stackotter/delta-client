//
//  Mesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit

protocol Mesh {
  var vertices: [Vertex] { get }
  var indices: [UInt32] { get }
}

extension Mesh {
  func createVertexBuffer(for device: MTLDevice) -> MTLBuffer {
    let bufferSize = MemoryLayout<Vertex>.stride * vertices.count
    let buffer = device.makeBuffer(bytes: vertices, length: bufferSize, options: [])!
    buffer.label = "vertexBuffer"
    return buffer
  }
  
  func createIndexBuffer(for device: MTLDevice) -> MTLBuffer {
    let bufferSize = MemoryLayout<UInt32>.stride * indices.count
    let buffer = device.makeBuffer(bytes: indices, length: bufferSize, options: [])!
    buffer.label = "indexBuffer"
    return buffer
  }
}
