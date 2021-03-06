//
//  MeshObject.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import simd

// NOTE: mesh coordinates and all that are in right handed coordinates
class Mesh {
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var translations: [simd_float3] = []
  
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
  
  func createTranslationsBuffer(for device: MTLDevice) -> MTLBuffer {
    let translationsSize = MemoryLayout<simd_float3>.stride * translations.count
    let buffer = device.makeBuffer(bytes: translations, length: translationsSize, options: [])!
    buffer.label = "translationsBuffer"
    return buffer
  }
}
