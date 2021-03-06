//
//  ChunkRenderer.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd
import os

class ChunkRenderer {
  let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  let cubeTextureCoordinates: [simd_float2] = [
    simd_float2(0, 0),
    simd_float2(0, 1),
    simd_float2(1, 1),
    simd_float2(1, 0)
  ]
  let cubeFaceVertices: [Direction: (Int, Int, Int, Int)] = [
    .up: (2, 1, 5, 6),
    .down: (0, 3, 7, 4),
    .east: (3, 2, 6, 7),
    .west: (1, 0, 4, 5),
    .north: (7, 6, 5, 4),
    .south: (0, 1, 2, 3)
  ]
  
  let cubeVertexPositions: [simd_float3] = [
    simd_float3([0,  1,  0]),
    simd_float3([0,  0,  0]),
    simd_float3([1,  0,  0]),
    simd_float3([1,  1,  0]),
    simd_float3([0,  1,  1]),
    simd_float3([0,  0,  1]),
    simd_float3([1,  0,  1]),
    simd_float3([1,  1,  1]),
  ]
  
  func renderBlock(into mesh: Mesh, position: simd_float3, faces: Set<Direction>) {
    for direction in faces {
      renderFace(into: mesh, direction: direction, blockPosition: position)
    }
  }
  
  func renderFace(into mesh: Mesh, direction: Direction, blockPosition: simd_float3) {
    let windingOffset = UInt32(mesh.vertices.count)
    let modelMatrix = MatrixUtil.translationMatrix(blockPosition)
    
    let faceVertexIndices = cubeFaceVertices[direction]!
    let vertexIndices = [faceVertexIndices.0, faceVertexIndices.1, faceVertexIndices.2, faceVertexIndices.3]
    
    for (textureCoordinateIndex, vertexIndex) in vertexIndices.enumerated() {
      let vertexPosition = simd_make_float3(simd_float4(cubeVertexPositions[vertexIndex], 1) * modelMatrix)
      let textureCoordinate = cubeTextureCoordinates[textureCoordinateIndex]
      mesh.vertices.append(
        Vertex(position: vertexPosition, textureCoordinate: textureCoordinate)
      )
    }
    
    var indices: [UInt32] = []
    for index in quadWinding {
      indices.append(index + windingOffset)
    }
    mesh.indices.append(contentsOf: indices)
  }
}
