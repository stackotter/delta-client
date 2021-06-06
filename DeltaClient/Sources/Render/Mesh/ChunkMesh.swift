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
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var uniforms = Uniforms()
  
  var hasChanged = false
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  
  private var blockPaletteManager: BlockPaletteManager
  
  // chunks
  var chunk: Chunk
  var chunkPosition: ChunkPosition
  var neighbourChunks: [CardinalDirection: Chunk]
  
  // maps block index to where its quads are in the vertex data
  private var blockIndexToQuads: [Int: [Int]] = [:]
  private var quadToBlockIndex: [Int: Int] = [:]
  
  private var stopwatch = Stopwatch(mode: .summary, name: "ChunkMesh")
  
  // cube geometry
  private let quadWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  private let quadVertexIndices: [FaceDirection: [Int]] = [
    .up: [3, 7, 4, 0],
    .down: [6, 2, 1, 5],
    .east: [3, 2, 6, 7],
    .west: [4, 5, 1, 0],
    .north: [0, 1, 2, 3],
    .south: [7, 6, 5, 4]]
  
  private let cubeVertexPositions: [simd_float3] = [
    simd_float3([0, 1, 0]),
    simd_float3([0, 0, 0]),
    simd_float3([1, 0, 0]),
    simd_float3([1, 1, 0]),
    simd_float3([0, 1, 1]),
    simd_float3([0, 0, 1]),
    simd_float3([1, 0, 1]),
    simd_float3([1, 1, 1])]
  
  init(blockPaletteManager: BlockPaletteManager, chunk: Chunk, position: ChunkPosition, neighbourChunks: [CardinalDirection: Chunk]) {
    self.blockPaletteManager = blockPaletteManager
    self.chunk = chunk
    self.chunkPosition = position
    self.neighbourChunks = neighbourChunks
  }
  
  func prepare() {
    hasChanged = true
    vertices = []
    indices = []
    quadToBlockIndex = [:]
    blockIndexToQuads = [:]
    
    // add blocks to mesh
    chunk.sections.enumerated().forEach { sectionIndex, section in
      if section.blockCount != 0 {
        
        let sectionY = sectionIndex * 16
        for y in 0..<16 {
          for z in 0..<16 {
            for x in 0..<16 {
              var position = Position(x: x, y: y, z: z)
              let sectionRelativeBlockIndex = position.blockIndex
              let state = section.getBlockState(at: sectionRelativeBlockIndex)
              if state != 0 {
                position.y += sectionY
                addBlock(at: position, with: state)
              }
            }
          }
        }
        
      }
    }
    
    // calculate model to world matrix
    let xOffset = chunkPosition.chunkX * 16
    let zOffset = chunkPosition.chunkZ * 16
    let modelToWorldMatrix = MatrixUtil.translationMatrix([Float(xOffset), 0.0, Float(zOffset)])
    uniforms = Uniforms(transformation: modelToWorldMatrix)
  }
  
  func getNeighbouringBlockStates(ofBlockAt index: Int) -> [FaceDirection: UInt16] {
    var neighbouringBlockStates: [FaceDirection: UInt16] = [:]
    
    if index % Chunk.blocksPerLayer >= Chunk.width {
      neighbouringBlockStates[.north] = chunk.getBlock(at: index - Chunk.width)
    } else {
      let neighbourBlockIndex = index + Chunk.blocksPerLayer - Chunk.width
      neighbouringBlockStates[.north] = neighbourChunks[.north]?.getBlock(at: neighbourBlockIndex)
    }
    
    if index % Chunk.blocksPerLayer < Chunk.blocksPerLayer - Chunk.width {
      neighbouringBlockStates[.south] = chunk.getBlock(at: index + Chunk.width)
    } else {
      let neighbourBlockIndex = index - Chunk.blocksPerLayer + Chunk.width
      neighbouringBlockStates[.south] = neighbourChunks[.south]?.getBlock(at: neighbourBlockIndex)
    }
    
    if index % Chunk.width != Chunk.width - 1 {
      neighbouringBlockStates[.east] = chunk.getBlock(at: index + 1)
    } else {
      let neighbourBlockIndex = index - 15
      neighbouringBlockStates[.east] = neighbourChunks[.east]?.getBlock(at: neighbourBlockIndex)
    }
    
    if index % Chunk.width != 0 {
      neighbouringBlockStates[.west] = chunk.getBlock(at: index - 1)
    } else {
      let neighbourBlockIndex = index + 15
      neighbouringBlockStates[.west] = neighbourChunks[.west]?.getBlock(at: neighbourBlockIndex)
    }
    
    if index < Chunk.numBlocks - Chunk.blocksPerLayer {
      neighbouringBlockStates[.up] = chunk.getBlock(at: index + Chunk.blocksPerLayer)
    }
    
    if index >= Chunk.blocksPerLayer {
      neighbouringBlockStates[.down] = chunk.getBlock(at: index - Chunk.blocksPerLayer)
    }
    
    return neighbouringBlockStates
  }
  
  func getCullingNeighbours(ofBlockAt index: Int, and position: Position) -> [FaceDirection] {
    let neighbouringBlockStates = getNeighbouringBlockStates(ofBlockAt: index)
    
    var cullingNeighbours: [FaceDirection] = []
    for (direction, neighbourBlockState) in neighbouringBlockStates where neighbourBlockState != 0 {
      if let blockModel = blockPaletteManager.getVariant(for: neighbourBlockState, at: position) {
        if blockModel.fullFaces.contains(direction.opposite) {
          cullingNeighbours.append(direction)
        }
      }
    }
    
    return cullingNeighbours
  }
  
  // mesh building functions
  
  private func addBlock(at index: Int, with state: UInt16) {
    let x = index & 0x0f
    let z = (index & 0xf0) >> 4
    let y = index >> 8
    let position = Position(x: x, y: y, z: z)
    addBlock(at: position, with: state)
  }
  
  private func addBlock(at position: Position, with state: UInt16) {
    let blockIndex = position.blockIndex
    let cullFaces = getCullingNeighbours(ofBlockAt: blockIndex, and: position)
    
    if let blockModel = blockPaletteManager.getVariant(for: state, at: position) {
      let modelToWorld = MatrixUtil.translationMatrix(position.floatVector)
      
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
          let quadIndex = addQuad(direction: faceDirection, matrix: vertexToWorld, face: face)
          
          quadIndices.append(quadIndex)
          quadToBlockIndex[quadIndex] = blockIndex
        }
      }
      
      if !quadIndices.isEmpty {
        blockIndexToQuads[position.blockIndex] = quadIndices
      }
    } else {
      Logger.debug("Skipping block with no block model")
    }
  }
  
  private func addQuad(direction: FaceDirection, matrix: matrix_float4x4, face: BlockModelElementFace) -> Int {
    // add windings
    let offset = UInt32(vertices.count) // the index of the first vertex of the quad
    for index in quadWinding {
      indices.append(index + offset)
    }
    
    // add vertices
    // swiftlint:disable force_unwrapping
    let vertexIndices = quadVertexIndices[direction]!
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
  
  func replaceBlock(at index: Int, with newState: UInt16, shouldUpdateNeighbours: Bool = true) {
    hasChanged = true
    removeBlock(atIndex: index)
    if newState != 0 {
      Logger.debug("add new block")
      addBlock(at: index, with: newState)
    }
    
    if shouldUpdateNeighbours {
      updateNeighbours(of: index)
    }
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
      Logger.error("Failed to get quad to remove, buckle-up, this could get bumpy")
      return
    }
    quads.remove(at: quadIndex)
    blockIndexToQuads[blockIndex] = quads
  }
  
  private func updateNeighbours(of index: Int) {
    // update non-air neighbours of neighbours to ensure faces are culled correctly
    let neighbours = chunk.getNonAirNeighbours(ofBlockAt: index)
    neighbours.forEach { _, neighbourBlockIndex in
      let neighbourBlockState = chunk.getBlock(at: neighbourBlockIndex)
      replaceBlock(
        at: neighbourBlockIndex,
        with: neighbourBlockState,
        shouldUpdateNeighbours: false)
    }
  }
}
