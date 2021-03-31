//
//  ChunkMesh.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import simd
import os

class ChunkMesh: Mesh {
  var chunk: Chunk
  
  private var blockPaletteManager: BlockPaletteManager
  
  // vertex data
  private let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  // maps block index to where its quads are in the vertex data
  private var blockIndexToQuads: [Int: [Int]] = [:]
  private var quadToBlockIndex: [Int: Int] = [:]
  
  private var profiler: Profiler
  private var stopwatch = Stopwatch(mode: .summary, name: "chunk mesh")
  
  // cube geometry constants
  private let faceVertexIndices: [FaceDirection: [Int]] = [
    .up: [3, 7, 4, 0],
    .down: [6, 2, 1, 5],
    .east: [3, 2, 6, 7],
    .west: [4, 5, 1, 0],
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
  
  init(blockPaletteManager: BlockPaletteManager, chunk: Chunk) {
    self.blockPaletteManager = blockPaletteManager
    self.chunk = chunk
    self.profiler = Profiler(name: "chunk mesh")
    
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
      
      stopwatch.startMeasurement("ingestChunk")
      for (sectionIndex, section) in chunk.sections.enumerated() {
        if section.blockCount != 0 { // section isn't empty
          let offset = sectionIndex * ChunkSection.NUM_BLOCKS
          for i in 0..<ChunkSection.NUM_BLOCKS {
            stopwatch.startMeasurement("ingestChunk: chunk section block")
            // get block state and add block to mesh if not air
            stopwatch.startMeasurement("ingestChunk: add block")
            let state = section.blocks[i]
            if state != 0 { // block isn't air
              let blockIndex = offset + i // block index in chunk
              
              addBlock(x, y, z, index: blockIndex, state: state)
            }
            stopwatch.stopMeasurement("ingestChunk: add block")
            
            // move xyz to next block with speedy magic
            stopwatch.startMeasurement("ingestChunk: update indices")
            x += 1
            z += (x == ChunkSection.WIDTH) ? 1 : 0
            y += (z == ChunkSection.DEPTH) ? 1 : 0
            x = x & 0xf
            z = z & 0xf
            stopwatch.stopMeasurement("ingestChunk: update indices")
            stopwatch.stopMeasurement("ingestChunk: chunk section block")
          }
        }
      }
      stopwatch.stopMeasurement("ingestChunk")
    }
    
    stopwatch.summary()
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
    let z = (index & 0xf0) >> 4
    let y = index >> 8
    addBlock(x, y, z, index: index, state: state)
  }
  
  private func addBlock(_ x: Int, _ y: Int, _ z: Int, index: Int, state: UInt16) {
    stopwatch.startMeasurement("getCullingNeighbours")
    let cullFaces = chunk.getCullingNeighbours(forIndex: index)
    stopwatch.stopMeasurement("getCullingNeighbours")
    
    if let blockModel = blockPaletteManager.blockModelPalette[state] {
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
          stopwatch.startMeasurement("addQuad")
          let quadIndex = addQuad(x, y, z, direction: faceDirection, matrix: vertexToWorld, face: face)
          stopwatch.stopMeasurement("addQuad")
          quadIndices.append(quadIndex)
          quadToBlockIndex[quadIndex] = index
        }
      }
      
      if !quadIndices.isEmpty {
        blockIndexToQuads[index] = quadIndices
      }
    } else {
      Logger.debug("skipping block because no block model found")
    }
  }
  
  private func addQuad(_ x: Int, _ y: Int, _ z: Int, direction: FaceDirection, matrix: matrix_float4x4, face: BlockModelElementFace) -> Int {
    // add windings
    stopwatch.startMeasurement("addQuad: add windings")
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    for index in quadWinding {
      indices.append(index + offset)
    }
    stopwatch.stopMeasurement("addQuad: add windings")
    
    // add vertices
    stopwatch.startMeasurement("addQuad: add vertices")
    let vertexIndices = faceVertexIndices[direction]!
    for (uvIndex, vertexIndex) in vertexIndices.enumerated() {
      let position = simd_float4(cubeVertexPositions[vertexIndex], 1) * matrix
      vertices.append(
        Vertex(position: simd_make_float3(position), uv: face.uvs[uvIndex], textureIndex: face.textureIndex, tintIndex: face.tintIndex)
      )
    }
    stopwatch.stopMeasurement("addQuad: add vertices")
    
    // get and return the quad's index
    let index = vertices.count / 4 - 1
    return index
  }
  
  
  
  // Mesh Editing Functions
  
  private func removeBlock(atIndex index: Int) {
    // multiply each quadIndex by 4 to get the start index of each of the block's rendered faces
    if let quads = blockIndexToQuads[index] {
      for i in (0..<quads.count).reversed() {
        removeQuad(atIndex: blockIndexToQuads[index]![i])
      }
      blockIndexToQuads.removeValue(forKey: index)
    }
  }
  
  private func removeQuad(atIndex quadIndex: Int) {
    let lastQuad = vertices.count / 4 - 1
    let isLastQuad = quadIndex == lastQuad
    let blockIndex = quadToBlockIndex[quadIndex]!
    
    indices.removeLast(quadWinding.count) // remove a winding
    
    if !isLastQuad {
      let lastBlockIndex = quadToBlockIndex[lastQuad]!
      quadToBlockIndex[quadIndex] = lastBlockIndex
      let indexOfIndex = blockIndexToQuads[lastBlockIndex]!.firstIndex(of: lastQuad)!
      blockIndexToQuads[lastBlockIndex]!.remove(at: indexOfIndex)
      blockIndexToQuads[lastBlockIndex]!.insert(quadIndex, at: indexOfIndex)
      
      let quadBegin = quadIndex * 4
      let quadEnd = quadBegin + 4
      vertices.replaceSubrange(quadBegin..<quadEnd, with: vertices.suffix(4))
    }
    quadToBlockIndex.removeValue(forKey: lastQuad)
    vertices.removeLast(4)
    
    blockIndexToQuads[blockIndex]!.remove(at: blockIndexToQuads[blockIndex]!.lastIndex(of: quadIndex)!)
  }
  
  private func updateNeighbours(of index: Int) {
    let presentNeighbours = chunk.getPresentNeighbours(forIndex: index)
    for (_, (neighbourChunk, neighbourIndex)) in presentNeighbours {
      neighbourChunk.mesh.queue.sync {
        let state = neighbourChunk.getBlock(atIndex: neighbourIndex)
        neighbourChunk.mesh.removeBlock(atIndex: neighbourIndex)
        neighbourChunk.mesh.addBlock(at: neighbourIndex, with: state)
      }
    }
  }
}
