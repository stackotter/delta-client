//
//  ChunkSectionMesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/3/21.
//

import Foundation
import MetalKit
import simd

class ChunkSectionMesh: Mesh {
  /// A lookup to quickly convert block index to block position
  static var indexToPosition = ChunkSectionMesh.generateIndexLookup()
  
  /// The `Chunk` containing the `Chunk.Section` to prepare
  var chunk: Chunk
  /// The position of the `Chunk.Section` to prepare
  var sectionPosition: ChunkSectionPosition
  /// The chunks surrounding `chunk`
  var neighbourChunks: [CardinalDirection: Chunk]
  
  private var blockPaletteManager: BlockPaletteManager
  private var stopwatch = Stopwatch(mode: .summary, name: "ChunkSectionMesh")
  
  init(
    forSectionAt sectionPosition: ChunkSectionPosition,
    in chunk: Chunk,
    withNeighbours neighbourChunks: [CardinalDirection: Chunk],
    blockPaletteManager: BlockPaletteManager
  ) {
    self.sectionPosition = sectionPosition
    self.chunk = chunk
    self.neighbourChunks = neighbourChunks
    self.blockPaletteManager = blockPaletteManager
    super.init()
  }
  
  /// Prepares the `Chunk.Section` at `sectionPosition` into the mesh
  func prepare() {
    vertices = []
    indices = []
    
    // add the section's blocks to the mesh
    let section = chunk.sections[sectionPosition.sectionY]
    if section.blockCount != 0 {
      let startTime = CFAbsoluteTimeGetCurrent()
      for blockIndex in 0..<Chunk.Section.numBlocks {
        let position = ChunkSectionMesh.indexToPosition[blockIndex]
        let state = section.getBlockState(at: blockIndex)
        if state != 0 {
          addBlock(at: position, with: state)
        }
      }
      let elapsed = CFAbsoluteTimeGetCurrent() - startTime
      log.debug("Prepared ChunkSectionMesh for Chunk.Section at \(sectionPosition) in \(elapsed) seconds")
    }
    
    // generate model to world transformation matrix
    let xOffset = sectionPosition.sectionX * 16
    let yOffset = sectionPosition.sectionY * 16
    let zOffset = sectionPosition.sectionZ * 16
    let modelToWorldMatrix = MatrixUtil.translationMatrix(
      [
        Float(xOffset),
        Float(yOffset),
        Float(zOffset)
      ])
    
    // set the mesh uniforms
    uniforms = Uniforms(transformation: modelToWorldMatrix)
  }
  
  /// Adds a block to the mesh at `position` with block state `state`.
  private func addBlock(at position: Position, with state: UInt16) {
    // TODO: reduce nesting in this function
    let blockIndex = position.blockIndex
    let cullFaces = getCullingNeighbours(ofBlockAt: blockIndex, and: position)
    
    if let blockModel = blockPaletteManager.getVariant(for: state, at: position) {
      let modelToWorld = MatrixUtil.translationMatrix(position.floatVector)
      
      for element in blockModel.elements {
        let vertexToWorld = element.modelMatrix * modelToWorld
        
        for (faceDirection, face) in element.faces {
          if let cullFace = face.cullface {
            if cullFaces.contains(cullFace) {
              // don't render face
              continue
            }
          }
          addFace(face, facing: faceDirection, transformedBy: vertexToWorld)
        }
      }
    } else {
      log.warning("Skipping block with no block model, blockState=\(state)")
    }
  }
  
  /// Adds the face described by `face` to the mesh, facing in `direction` and transformed by `transformation`.
  private func addFace(
    _ face: BlockModelElementFace,
    facing direction: FaceDirection,
    transformedBy transformation: matrix_float4x4
  ) {
    // add face winding
    let offset = UInt32(vertices.count) // the index of the first vertex of face
    for index in CubeGeometry.faceWinding {
      indices.append(index + offset)
    }
    
    // swiftlint:disable force_unwrapping
    // this lookup will never be nil cause every direction is included in the static lookup table
    let faceVertexPositions = CubeGeometry.faceVertices[direction]!
    // swiftlint:enable force_unwrapping
    
    // add vertices to mesh
    for (uvIndex, vertexPosition) in faceVertexPositions.enumerated() {
      let position = simd_float4(vertexPosition, 1) * transformation
      vertices.append(
        Vertex(
          position: simd_make_float3(position),
          uv: face.uvs[uvIndex],
          light: face.light,
          textureIndex: face.textureIndex,
          tintIndex: face.tintIndex)
      )
    }
  }
  
  /**
   Gets the block state of each block neighbouring the block at `sectionIndex`.
   
   Blocks in neighbouring chunks are also included. Neighbours in cardinal directions will
   always be returned. If the block at `sectionIndex` is at y-level 0 or 255 the down or up neighbours
   will be omitted respectively (as there will be none). Otherwise, all neighbours are included.
   
   The function is implemented the verbose non-dynamic way it is to improve performance.
   
   - Returns: A a mapping from each possible direction to a corresponding block state.
   */
  func getNeighbouringBlockStates(ofBlockAt index: Int) -> [FaceDirection: UInt16] {
    // convert a section relative index to a chunk relative index
    let indexInChunk = index + sectionPosition.sectionY * Chunk.Section.numBlocks
    var neighbouringBlockStates: [FaceDirection: UInt16] = [:]
    
    if indexInChunk % Chunk.blocksPerLayer >= Chunk.width {
      neighbouringBlockStates[.north] = chunk.getBlock(at: indexInChunk - Chunk.width)
    } else {
      let neighbourBlockIndex = indexInChunk + Chunk.blocksPerLayer - Chunk.width
      neighbouringBlockStates[.north] = neighbourChunks[.north]?.getBlock(at: neighbourBlockIndex)
    }
    
    if indexInChunk % Chunk.blocksPerLayer < Chunk.blocksPerLayer - Chunk.width {
      neighbouringBlockStates[.south] = chunk.getBlock(at: indexInChunk + Chunk.width)
    } else {
      let neighbourBlockIndex = indexInChunk - Chunk.blocksPerLayer + Chunk.width
      neighbouringBlockStates[.south] = neighbourChunks[.south]?.getBlock(at: neighbourBlockIndex)
    }
    
    if indexInChunk % Chunk.width != Chunk.width - 1 {
      neighbouringBlockStates[.east] = chunk.getBlock(at: indexInChunk + 1)
    } else {
      let neighbourBlockIndex = indexInChunk - 15
      neighbouringBlockStates[.east] = neighbourChunks[.east]?.getBlock(at: neighbourBlockIndex)
    }
    
    if indexInChunk % Chunk.width != 0 {
      neighbouringBlockStates[.west] = chunk.getBlock(at: indexInChunk - 1)
    } else {
      let neighbourBlockIndex = indexInChunk + 15
      neighbouringBlockStates[.west] = neighbourChunks[.west]?.getBlock(at: neighbourBlockIndex)
    }
    
    if indexInChunk < Chunk.numBlocks - Chunk.blocksPerLayer {
      neighbouringBlockStates[.up] = chunk.getBlock(at: indexInChunk + Chunk.blocksPerLayer)
    }
    
    if indexInChunk >= Chunk.blocksPerLayer {
      neighbouringBlockStates[.down] = chunk.getBlock(at: indexInChunk - Chunk.blocksPerLayer)
    }
    
    return neighbouringBlockStates
  }
  
  /**
   Gets an array of the direction of all blocks neighbouring the block at `sectionIndex` that have
   full faces facing the block at `sectionIndex`.
   
   `position` is only used to determine which variation of a block model to use when a block model
   has multiple variations. Both `sectionIndex` and `position` are required for performance reasons as this
   function is called a lot and causes significant bottlenecks during mesh preparing.
   
   - Parameter sectionIndex: The sectionIndex of the block in `chunk`.
   - Parameter position: The position of the block relative to `sectionPosition`.
   
   - Returns: A list of directions of neighbours that can possibly cull a face.
   */
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
  
  /// Generates a lookup table to quickly convert from section block index to block position
  private static func generateIndexLookup() -> [Position] {
    var lookup: [Position] = []
    for y in 0..<16 {
      for z in 0..<16 {
        for x in 0..<16 {
          let position = Position(x: x, y: y, z: z)
          lookup.append(position)
        }
      }
    }
    return lookup
  }
}
