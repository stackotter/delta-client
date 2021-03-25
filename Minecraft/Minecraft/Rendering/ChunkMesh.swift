//
//  ChunkMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import simd

class ChunkMesh: Mesh {
  var chunk: Chunk
  var totalBlocks = 0
  
  private var blockModelManager: BlockModelManager
  
  // vertex data
  private let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  // maps block index to where its quads are in the vertex data
  private var blockIndexToQuads: [Int: [Int]] = [:]
  private var quadToBlockIndex: [Int: Int] = [:]
  
  // debug stopwatch
  private var stopwatch = Stopwatch(mode: .summary, name: "chunk ingest")
  
  // cube geometry constants
  private let cubeTextureCoordinates: [simd_float2] = [
    simd_float2(0, 0),
    simd_float2(0, 1),
    simd_float2(1, 1),
    simd_float2(1, 0)
  ]
  
  private let faceVertexIndices: [FaceDirection: [Int]] = [
    .up: [0, 3, 7, 4],
    .down: [2, 1, 5, 6],
    .east: [3, 2, 6, 7],
    .west: [1, 0, 4, 5],
    .north: [0, 1, 2, 3],
    .south: [7, 6, 5, 4]
  ]
  
  private let cubeVertexPositions: [simd_float3] = [
    simd_float3([0,  1,  0]),
    simd_float3([0,  0,  0]),
    simd_float3([1,  0,  0]),
    simd_float3([1,  1,  0]),
    simd_float3([0,  1,  1]),
    simd_float3([0,  0,  1]),
    simd_float3([1,  0,  1]),
    simd_float3([1,  1,  1]),
  ]
  
  init(blockModelManager: BlockModelManager, chunk: Chunk) {
    self.blockModelManager = blockModelManager
    self.chunk = chunk
    
    super.init()
  }
  
  // public interface functions
  
  func ingestChunk() {
    queue.sync {
      vertices = []
      indices = []
      quadToBlockIndex = [:]
      blockIndexToQuads = [:]
      
      var x = 0
      var y = 0
      var z = 0
      
      for (sectionIndex, section) in chunk.sections.enumerated() {
        if section.blockCount != 0 { // section isn't empty
          let offset = sectionIndex * ChunkSection.NUM_BLOCKS
          for i in 0..<ChunkSection.NUM_BLOCKS {
            // get block state and add block to mesh if not air
            let state = section.blocks[i]
            if state != 0 { // block isn't air
              let blockIndex = offset + i // block index in chunk
              addBlock(x , y, z, index: blockIndex, state: state)
            }
            
            // move xyz to next block with speedy magic
            x += 1
            z += (x == ChunkSection.WIDTH) ? 1 : 0
            y += (z == ChunkSection.DEPTH) ? 1 : 0
            x = x & 0xf
            z = z & 0xf
          }
        }
      }
    }
  }
  
  func replaceBlock(at index: Int, newState: UInt16) {
    queue.sync {
      removeBlock(atIndex: index)
      if newState != 0 {
        addBlock(at: index, with: newState)
      }
    }
    updateNeighbours(of: index)
  }
  
  // mesh building functions
  
  private func addBlock(at index: Int, with state: UInt16) {
    let x = index & 0x0f
    let z = index & 0xf0 >> 4
    let y = index >> 8
    addBlock(x, y, z, index: index, state: state)
  }
  
  private func addBlock(_ x: Int, _ y: Int, _ z: Int, index: Int, state: UInt16) {
    let cullFaces = chunk.getPresentNeighbours(forIndex: index).keys
    
    if let blockModel = blockModelManager.blockModelPalette[state] {
      var quadIndices: [Int] = []
      
      let modelToWorld = MatrixUtil.translationMatrix(simd_float3(Float(x), Float(y), Float(z)))
      for element in blockModel.elements {
        let vertexToWorld = element.modelMatrix * modelToWorld
        
        for (faceDirection, face) in element.faces {
          if let cullFace = face.cullface {
            if cullFaces.contains(cullFace) {
              continue // face doesn't need to be rendered
            }
          }
          let quadIndex = addQuad(x, y, z, direction: faceDirection, matrix: vertexToWorld, face: face)
          quadIndices.append(quadIndex)
          quadToBlockIndex[quadIndex] = index
        }
      }
      
      blockIndexToQuads[index] = quadIndices
      totalBlocks += 1
    }
  }
  
  private func addQuad(_ x: Int, _ y: Int, _ z: Int, direction: FaceDirection, matrix: matrix_float4x4, face: BlockModelElementFace) -> Int {
    // add windings
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    for index in quadWinding {
      indices.append(index + offset)
    }
    
    // create uv's
    let minUV = face.uv.0
    let maxUV = face.uv.1
    let uvs = [
      minUV,
      simd_float2(minUV.x, maxUV.y),
      maxUV,
      simd_float2(maxUV.x, minUV.y)
    ]
    
    // add vertices
    let vertexIndices = faceVertexIndices[direction]!
    for (uvIndex, vertexIndex) in vertexIndices.enumerated() {
      let position = simd_float4(cubeVertexPositions[vertexIndex], 1) * matrix
      let uv = uvs[uvIndex]
      vertices.append(
        Vertex(position: simd_make_float3(position), uv: uv, textureIndex: face.textureIndex)
      )
    }
    
    // get and return the quad's index
    let index = vertices.count / 4 - 1
    return index
  }
  
  // Mesh Editing Functions
  
  private func removeBlock(atIndex index: Int) {
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
  
  private func removeQuad(atIndex quadIndex: Int) {
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
  
  private func updateNeighbours(of index: Int) {
    let presentNeighbours = chunk.getPresentNeighbours(forIndex: index)
    for (_, (neighbourChunk, neighbourIndex)) in presentNeighbours {
      let state = neighbourChunk.getBlock(atIndex: index)
      neighbourChunk.mesh.replaceBlock(at: neighbourIndex, newState: state)
    }
  }
}
