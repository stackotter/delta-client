//
//  ChunkMesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import MetalKit
import simd


class ChunkMesh: Mesh {
  typealias Uniforms = ChunkUniforms
  
  var chunk: Chunk
  var queue: DispatchQueue
  
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var uniforms: ChunkUniforms!
  
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  
  var hasChanged: Bool = false
  
  private var blockPaletteManager: BlockPaletteManager
  
  // maps block index to where its quads are in the vertex data
  private var blockIndexToQuads: [Int: [Int]] = [:]
  private var quadToBlockIndex: [Int: Int] = [:]
  
  private var stopwatch = Stopwatch(mode: .summary, name: "ChunkMesh")
  
  // cube geometry constants
  private let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  private let faceVertexIndices: [FaceDirection: [Int]] = [
    .up: [3, 7, 4, 0],
    .down: [6, 2, 1, 5],
    .east: [3, 2, 6, 7],
    .west: [4, 5, 1, 0],
    .north: [0, 1, 2, 3],
    .south: [7, 6, 5, 4]
  ]
  
  private let cubeVertexPositions: [simd_float3] = [
    simd_float3([0, 1, 0]),
    simd_float3([0, 0, 0]),
    simd_float3([1, 0, 0]),
    simd_float3([1, 1, 0]),
    simd_float3([0, 1, 1]),
    simd_float3([0, 0, 1]),
    simd_float3([1, 0, 1]),
    simd_float3([1, 1, 1])
  ]
  
  init(blockPaletteManager: BlockPaletteManager, chunk: Chunk) {
    self.blockPaletteManager = blockPaletteManager
    self.chunk = chunk
    self.queue = DispatchQueue(label: "chunkMesh")
  }
  
  // public interface functions
  
  func ingestChunk() {
    queue.sync {
      hasChanged = true
      vertices = []
      indices = []
      quadToBlockIndex = [:]
      blockIndexToQuads = [:]
      
      // TODO: cache this
      stopwatch.startMeasurement("generate indexToCoordinates")
      var indexToCoordinates: [Position] = []
      for y in 0..<16 {
        for z in 0..<16 {
          for x in 0..<16 {
            let position = Position(x: x, y: y, z: z)
            indexToCoordinates.append(position)
          }
        }
      }
      stopwatch.stopMeasurement("generate indexToCoordinates")
      
      stopwatch.startMeasurement("generate mesh")
      for (sectionIndex, section) in chunk.sections.enumerated() where section.blockCount != 0 {
        let offset = sectionIndex * ChunkSection.NUM_BLOCKS
        for i in 0..<ChunkSection.NUM_BLOCKS {
          // get block state and add block to mesh if not air
          let state = section.blocks[i]
          if state != 0 { // block isn't air
            let blockIndex = offset + i // block index in chunk
            // TODO: decide if index to coordinates caching actually saves time
            var position = indexToCoordinates[i]
            position.y += sectionIndex * 16
            
            addBlock(position.x, position.y, position.z, index: blockIndex, state: state)
          }
        }
      }
      stopwatch.stopMeasurement("generate mesh")
      
      stopwatch.summary()
      
      let xOffset = chunk.position.chunkX * 16
      let zOffset = chunk.position.chunkZ * 16
      let modelToWorldMatrix = MatrixUtil.translationMatrix([Float(xOffset), 0.0, Float(zOffset)])
      
      uniforms = ChunkUniforms(modelToWorld: modelToWorldMatrix)
    }
  }
  
  // mesh building functions
  
  private func addBlock(at index: Int, with state: UInt16) {
    let x = index & 0x0f
    let z = (index & 0xf0) >> 4
    let y = index >> 8
    addBlock(x, y, z, index: index, state: state)
  }
  
  private func addBlock(_ x: Int, _ y: Int, _ z: Int, index: Int, state: UInt16) {
    let cullFaces = chunk.getCullingNeighbours(forIndex: index, x: x, y: y, z: z)
    
    if let blockModel = blockPaletteManager.getVariant(for: state, x: x, y: y, z: z) {
      let modelToWorld = MatrixUtil.translationMatrix(simd_float3(Float(x), Float(y), Float(z)))
      
      var quadIndices: [Int] = []
      for element in blockModel.elements {
        let vertexToWorld = element.modelMatrix * modelToWorld
        
        for (faceDirection, face) in element.faces {
          if let cullFace = face.cullface {
            if cullFaces.contains(cullFace) {
              // don't render face
              continue
            }
          }
          let quadIndex = addQuad(x, y, z, direction: faceDirection, matrix: vertexToWorld, face: face)
          
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
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    for index in quadWinding {
      indices.append(index + offset)
    }
    
    // add vertices
    // swiftlint:disable force_unwrapping
    let vertexIndices = faceVertexIndices[direction]!
    // swiftlint:enable force_unwrapping
    for (uvIndex, vertexIndex) in vertexIndices.enumerated() {
      let position = simd_float4(cubeVertexPositions[vertexIndex], 1) * matrix
      vertices.append(
        Vertex(position: simd_make_float3(position), uv: face.uvs[uvIndex], light: face.light, textureIndex: face.textureIndex, tintIndex: face.tintIndex)
      )
    }
    
    // get and return the quad's index
    let index = vertices.count / 4 - 1
    return index
  }
  
  // Mesh Editing Functions
  
  func replaceBlock(at index: Int, newState: UInt16) {
    queue.sync {
      hasChanged = true
      removeBlock(atIndex: index)
      if newState != 0 {
        Logger.debug("add new block")
        addBlock(at: index, with: newState)
      }
    }
    
    updateNeighbours(of: index)
  }
  
  private func removeBlock(atIndex index: Int) {
    // multiply each quadIndex by 4 to get the start index of each of the block's rendered faces
    if let quads = blockIndexToQuads[index] {
      for i in (0..<quads.count).reversed() {
        removeQuad(atIndex: quads[i])
      }
      blockIndexToQuads.removeValue(forKey: index)
    }
  }
  
  private func removeQuad(atIndex quadIndex: Int) {
    let lastQuad = vertices.count / 4 - 1
    let isLastQuad = quadIndex == lastQuad
    guard let blockIndex = quadToBlockIndex[quadIndex] else {
      Logger.error("failed to remove quad from chunk mesh")
      return
    }
    
    indices.removeLast(quadWinding.count) // remove a winding
    
    if !isLastQuad {
      guard
        let lastBlockIndex = quadToBlockIndex[lastQuad],
        var lastBlockQuads = blockIndexToQuads[lastBlockIndex],
        let indexOfIndex = lastBlockQuads.firstIndex(of: lastQuad)
      else {
        Logger.error("failed to get index/quads of last block in mesh")
        return
      }
      lastBlockQuads.remove(at: indexOfIndex)
      lastBlockQuads.insert(quadIndex, at: indexOfIndex)
      blockIndexToQuads[lastBlockIndex] = lastBlockQuads
      quadToBlockIndex[quadIndex] = lastBlockIndex
      
      let quadBegin = quadIndex * 4
      let quadEnd = quadBegin + 4
      vertices.replaceSubrange(quadBegin..<quadEnd, with: vertices.suffix(4))
    }
    quadToBlockIndex.removeValue(forKey: lastQuad)
    vertices.removeLast(4)
    
    guard
      var quads = blockIndexToQuads[blockIndex],
      let quadIndex = quads.lastIndex(of: quadIndex)
    else {
      Logger.error("failed to get quad to remove, buckle-up, this could get bumpy")
      return
    }
    quads.remove(at: quadIndex)
    blockIndexToQuads[blockIndex] = quads
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
