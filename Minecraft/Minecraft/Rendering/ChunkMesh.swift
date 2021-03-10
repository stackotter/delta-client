//
//  ChunkMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import simd

struct ChunkMesh {
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  // maps block index to where its quads are in the vertex data
  var blockIndexToQuads: [Int: [Int]] = [:]
  var quadToBlockIndex: [Int: Int] = [:]
  
  var totalBlocks = 0
  
  // TODO: make chunkmesh constants static
  // cube geometry constants
  let cubeTextureCoordinates: [simd_float2] = [
    simd_float2(0, 0),
    simd_float2(0, 1),
    simd_float2(1, 1),
    simd_float2(1, 0)
  ]
  
  let faceVertexIndices: [Direction: [Int]] = [
    .up: [2, 1, 5, 6],
    .down: [0, 3, 7, 4],
    .east: [3, 2, 6, 7],
    .west: [1, 0, 4, 5],
    .north: [7, 6, 5, 4],
    .south: [0, 1, 2, 3]
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
  
  init() {
    
  }
  
  // Basic functions
  
  func blockIndexFrom(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return (y*16 + z)*16 + x
  }
  
//  func getBlock(_ x: Int, _ y: Int, _ z: Int) -> UInt16 {
//    let index = ChunkSection.blockIndexFrom(x, y, z)
//    return blocks[index]
//  }
//
//  mutating func setBlock(_ x: Int, _ y: Int, _ z: Int, to newState: UInt16) {
//    let index = ChunkSection.blockIndexFrom(x, y, z)
//    let currentState = blocks[index]
//    if currentState == newState {
//      return
//    }
//    removeBlock(atIndex: index) // TODO: implement replace block
//    if newState != 0 {
//      addBlock(x, y, z, index: index, faces: Set<Direction>([.up, .down, .east, .west, .north, .south]))
//    }
//    blocks[index] = newState
//  }
  
  // Render Functions
  
  mutating func addBlock(_ x: Int, _ y: Int, _ z: Int, faces: Set<Direction>) {
    let index = blockIndexFrom(x, y, z)
    addBlock(x, y, z, index: index, faces: faces)
  }
  
  mutating func addBlock(_ x: Int, _ y: Int, _ z: Int, index blockIndex: Int, faces: Set<Direction>) {
    totalBlocks += 1
    let startQuadIndex = vertices.count/4
    for faceDirection in faces {
      addQuad(x, y, z, direction: faceDirection)
    }
    var quadIndices: [Int] = []
    for i in 0..<faces.count {
      let quadIndex = startQuadIndex+i
      quadIndices.append(quadIndex)
      quadToBlockIndex[quadIndex] = blockIndex
    }
    blockIndexToQuads[blockIndex] = quadIndices
  }
  
  mutating func addQuad(_ x: Int, _ y: Int, _ z: Int, direction: Direction) {
    // TODO: compute this in addBlock
    let modelMatrix = MatrixUtil.translationMatrix(simd_float3(Float(x), Float(y), Float(z)))
    
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    windQuad(offset: offset)
    
    let vertexIndices = faceVertexIndices[direction]!
    for (textureCoordinateIndex, vertexIndex) in vertexIndices.enumerated() {
      let vertexPosition = simd_make_float3(simd_float4(cubeVertexPositions[vertexIndex], 1) * modelMatrix)
      let textureCoordinate = cubeTextureCoordinates[textureCoordinateIndex]
      vertices.append(
        Vertex(position: vertexPosition, textureCoordinate: textureCoordinate)
      )
    }
  }
  
  mutating func windQuad(offset: UInt32) {
    for index in quadWinding {
      indices.append(index + offset)
    }
  }
  
  mutating func removeBlock(atIndex index: Int) {
    // multiply each quadIndex by 4 to get the start index of each of the block's rendered faces
    if blockIndexToQuads[index] != nil {
      print("removing block")
      let numQuads = blockIndexToQuads[index]!.count
      for i in (0..<numQuads).reversed() {
        removeQuad(atIndex: blockIndexToQuads[index]![i])
        print("removing quad")
      }
      blockIndexToQuads.removeValue(forKey: index)
    }
  }
  
  mutating func removeQuad(atIndex quadIndex: Int) {
    let isLastQuad = quadIndex*4+4 == vertices.count
    indices.removeLast(6) // remove a winding
    
    let oldBlockIndex = quadToBlockIndex[quadIndex]!
    if !isLastQuad {
      quadToBlockIndex[quadIndex] = quadToBlockIndex[vertices.count/4]
      vertices.replaceSubrange((quadIndex*4)..<(quadIndex*4+4), with: vertices.suffix(4))
    }
    quadToBlockIndex.removeValue(forKey: vertices.count/4)
    vertices.removeLast(4)
    
    blockIndexToQuads[oldBlockIndex]?.removeAll { $0 == quadIndex }
  }
}
