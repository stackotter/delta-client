//
//  CubeMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

// TODO: profile and optimise cube mesh because it'll be used a lot
// NOTE: mesh coordinates and all that are in right handed coordinates but ndc is not (z towards camera)
class CubeMesh: Mesh {
  var faces: CubeFaces
  var position: simd_float3
  
  var cubeVertexCoordinates = [
    simd_float3([ 0,  1,  0]),
    simd_float3([ 0,  0,  0]),
    simd_float3([ 1,  0,  0]),
    simd_float3([ 1,  1,  0]),
    simd_float3([ 0,  1,  1]),
    simd_float3([ 0,  0,  1]),
    simd_float3([ 1,  0,  1]),
    simd_float3([ 1,  1,  1]),
  ]
  
  init(faces: CubeFaces, position: simd_float3) {
    self.faces = faces
    self.position = position
  }
  
  // could improve with fact that cubes will only show one face at a time (more efficient optionset)
  // make face vertices constants
  func prepare(into targetMesh: Mesh?=nil) {
    if faces.contains(.bottom) {
      windFace((0, 3, 7, 4), into: targetMesh)
    }
    if faces.contains(.top) {
      windFace((2, 1, 5, 6), into: targetMesh)
    }
    if faces.contains(.right) {
      windFace((1, 0, 4, 5), into: targetMesh)
    }
    if faces.contains(.left) {
      windFace((3, 2, 6, 7), into: targetMesh)
    }
    if faces.contains(.back) {
      windFace((0, 1, 2, 3), into: targetMesh)
    }
    if faces.contains(.front) {
      windFace((7, 6, 5, 4), into: targetMesh)
    }
  }
  
  // winds vertices of face in anticlockwise order
  func windFace(_ vertexIndices: (UInt32, UInt32, UInt32, UInt32), into targetMesh: Mesh?) {
    let mesh = targetMesh ?? self
    
    let numVertices = UInt32(mesh.vertices.count)
    let faceIndices: [UInt32] = [
      0 + numVertices,
      1 + numVertices,
      2 + numVertices,
      2 + numVertices,
      3 + numVertices,
      0 + numVertices
    ]
    mesh.indices.append(contentsOf: faceIndices)
    
    let translationIndex = UInt32(mesh.translations.count)
    let faceVertices: [Vertex] = [
      Vertex(position: cubeVertexCoordinates[Int(vertexIndices.0)], modelToWorldTranslationIndex: translationIndex, textureCoordinate: [0, 0]),
      Vertex(position: cubeVertexCoordinates[Int(vertexIndices.1)], modelToWorldTranslationIndex: translationIndex, textureCoordinate: [0, 1]),
      Vertex(position: cubeVertexCoordinates[Int(vertexIndices.2)], modelToWorldTranslationIndex: translationIndex, textureCoordinate: [1, 1]),
      Vertex(position: cubeVertexCoordinates[Int(vertexIndices.3)], modelToWorldTranslationIndex: translationIndex, textureCoordinate: [1, 0])
    ]
    mesh.vertices.append(contentsOf: faceVertices)
    
    mesh.translations.append(position)
  }
}
