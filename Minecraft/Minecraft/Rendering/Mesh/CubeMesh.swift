//
//  CubeMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

struct CubeMesh: Mesh {
  var color: vector_float4 = [1, 0, 1, 1]
  var indices: [UInt32] = []
  
  var vertices = [
    Vertex(position: [-1,  1,-1], color: [0, 0, 1, 1]),
    Vertex(position: [-1, -1,-1], color: [0, 0, 1, 1]),
    Vertex(position: [ 1, -1,-1], color: [0, 0, 1, 1]),
    Vertex(position: [ 1,  1,-1], color: [0, 0, 1, 1]),
    Vertex(position: [-1,  1, 1], color: [1, 0, 1, 1]),
    Vertex(position: [-1, -1, 1], color: [1, 0, 1, 1]),
    Vertex(position: [ 1, -1, 1], color: [1, 0, 1, 1]),
    Vertex(position: [ 1,  1, 1], color: [1, 0, 1, 1])
  ]
  
  // could improve with fact that cubes will only show one face at a time (more efficient optionset)
  // make face vertices constants
  init(faces: CubeFaces) {
    if faces.contains(.top) {
      windFace([0, 3, 7, 4])
    }
    if faces.contains(.bottom) {
      windFace([2, 1, 5, 6])
    }
    if faces.contains(.left) {
      windFace([1, 0, 4, 5])
    }
    if faces.contains(.right) {
      windFace([3, 2, 6, 7])
    }
    if faces.contains(.front) {
      windFace([0, 1, 2, 3])
    }
    if faces.contains(.back) {
      windFace([7, 6, 5, 4])
    }
  }
  
  // winds vertices of face in anticlockwise order
  mutating func windFace(_ vertices: vector_uint4) {
    let faceIndices = [
      vertices.x,
      vertices.y,
      vertices.z,
      vertices.z,
      vertices.w,
      vertices.x
    ]
    indices.append(contentsOf: faceIndices)
  }
}
