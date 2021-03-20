//
//  ChunkMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import simd

struct ChunkMesh {
  // vertex data
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  // maps block index to where its quads are in the vertex data
  var blockIndexToQuads: [Int: [Int]] = [:]
  var quadToBlockIndex: [Int: Int] = [:]
  
  var totalBlocks = 0
  
  // cube geometry constants
  let cubeTextureCoordinates: [simd_float2] = [
    simd_float2(0, 0),
    simd_float2(0, 1),
    simd_float2(1, 1),
    simd_float2(1, 0)
  ]
  
  let faceVertexIndices: [FaceDirection: [Int]] = [
    .up: [0, 3, 7, 4],
    .down: [2, 1, 5, 6],
    .east: [3, 2, 6, 7],
    .west: [1, 0, 4, 5],
    .north: [0, 1, 2, 3],
    .south: [7, 6, 5, 4]
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
  
  // TODO: don't loop through coords, just loop through indices instead
  mutating func ingestChunk(chunk: Chunk, blockModelManager: BlockModelManager) {
    // clear mesh
    vertices = []
    indices = []
    quadToBlockIndex = [:]
    blockIndexToQuads = [:]
    
    var stopwatch = Stopwatch(mode: .summary, name: "chunk ingest")
    
    stopwatch.startMeasurement(category: "entire loop")
    for (sectionIndex, section) in chunk.sections.enumerated() {
      if section.blockCount != 0 {
        let sectionY = sectionIndex * 16
        stopwatch.startMeasurement(category: "section \(sectionIndex)")
        stopwatch.startMeasurement(category: "section")
        for i in 0..<4096 {
          let state = section.blocks[i]
          if state != 0 {
            stopwatch.startMeasurement(category: "non-air block")
            let x = i & 0x00f
            let z = (i & 0x0f0) >> 4
            let y = (i >> 8) + sectionY
            stopwatch.startMeasurement(category: "determine cull faces")
            let cullFaces = chunk.getPresentNeighbours(forX: x, y: y, andZ: z)
            stopwatch.stopMeasurement(category: "determine cull faces")
            if let blockModel = blockModelManager.blockModelPalette[state] {
              stopwatch.startMeasurement(category: "add block")
              addBlock(x, y, z, state, cullFaces, blockModel)
              stopwatch.stopMeasurement(category: "add block")
            }
            stopwatch.stopMeasurement(category: "non-air block")
          }
        }
        stopwatch.stopMeasurement(category: "section \(sectionIndex)")
        stopwatch.stopMeasurement(category: "section")
      }
    }
    stopwatch.stopMeasurement(category: "entire loop")
    
    stopwatch.summary()
  }
  
  // Helper Functions
  
  func blockIndexFrom(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return (y*16 + z)*16 + x
  }
  
  // Render Functions
  
  mutating func addBlock(_ x: Int, _ y: Int, _ z: Int, _ state: UInt16, _ cullFaces: Set<FaceDirection>, _ blockModel: BlockModel) {
    var quadIndices: [Int] = []
    
    for element in blockModel.elements {
      let modelMatrix = element.modelMatrix
      for (faceDirection, face) in element.faces {
        if let cullFace = face.cullface {
          if cullFaces.contains(cullFace) {
            continue // face doesn't need to be rendered
          }
        }
        let quadIndex = addQuad(x, y, z, direction: faceDirection, modelMatrix: modelMatrix, face: face)
        quadIndices.append(quadIndex)
      }
    }
    
    let index = blockIndexFrom(x, y, z)
    blockIndexToQuads[index] = quadIndices
    
    totalBlocks += 1
  }
  
  mutating func addQuad(_ x: Int, _ y: Int, _ z: Int, direction: FaceDirection, modelMatrix: matrix_float4x4, face: BlockModelElementFace) -> Int {
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    windQuad(offset: offset)
    
    let minUV = face.uv.0
    let maxUV = face.uv.1
    let uvs = [
      minUV,
      simd_float2(minUV.x, maxUV.y),
      maxUV,
      simd_float2(maxUV.x, minUV.y)
    ]
    
    let modelToWorld = MatrixUtil.translationMatrix(simd_float3(Float(x), Float(y), Float(z)))
    
    let vertexIndices = faceVertexIndices[direction]!
    for (uvIndex, vertexIndex) in vertexIndices.enumerated() {
      let position = simd_float4(cubeVertexPositions[vertexIndex], 1) * modelMatrix * modelToWorld
      let uv = uvs[uvIndex]
      vertices.append(
        Vertex(position: simd_make_float3(position), uv: uv, textureIndex: face.textureIndex)
      )
    }
    
    let index = vertices.count/4
    return index
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
