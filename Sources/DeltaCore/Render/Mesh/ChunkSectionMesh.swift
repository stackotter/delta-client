//
//  ChunkSectionMesh.swift
//  DeltaCore
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
          tintIndex: face.tintIndex,
          skyLightLevel: 15,
          blockLightLevel: 15)
      )
    }
  }
  
  /**
   Gets the block state of each block neighbouring the block at `sectionIndex`.
   
   Blocks in neighbouring chunks are also included. Neighbours in cardinal directions will
   always be returned. If the block at `sectionIndex` is at y-level 0 or 255 the down or up neighbours
   will be omitted respectively (as there will be none). Otherwise, all neighbours are included.
   
   - Returns: A mapping from each possible direction to a corresponding block state.
   */
  func getNeighbouringBlockStates(ofBlockAt index: Int) -> [FaceDirection: UInt16] {
    // convert a section relative index to a chunk relative index
    var neighbouringBlockStates: [FaceDirection: UInt16] = [:]
    
    let neighbourIndices = getNeighbourIndices(ofBlockAt: index)
    for (faceDirection, neighbourBlock) in neighbourIndices {
      let blockState: UInt16?
      if let direction = neighbourBlock.chunkDirection {
        blockState = neighbourChunks[direction]?.getBlock(at: neighbourBlock.index)
      } else {
        blockState = chunk.getBlock(at: neighbourBlock.index)
      }
      neighbouringBlockStates[faceDirection] = blockState
    }
    
    return neighbouringBlockStates
  }
  
  /**
   Returns a map from each direction to a cardinal direction and a chunk relative block index.
   
   The cardinal direction is which chunk a neighbour resides in. If the cardinal direction for
   a neighbour is nil then the neighbour is in the current chunk.
   
   - Parameter index: A section-relative block index
   */
  func getNeighbourIndices(ofBlockAt index: Int) -> [FaceDirection: (chunkDirection: CardinalDirection?, index: Int)] {
    let indexInChunk = index + sectionPosition.sectionY * Chunk.Section.numBlocks
    var neighbouringIndices: [FaceDirection: (chunkDirection: CardinalDirection?, index: Int)] = [:]
    
    if indexInChunk % Chunk.blocksPerLayer >= Chunk.width {
      neighbouringIndices[.north] = (nil, indexInChunk - Chunk.width)
    } else {
      neighbouringIndices[.north] = (chunkDirection: .north, index: indexInChunk + Chunk.blocksPerLayer - Chunk.width)
    }
    
    if indexInChunk % Chunk.blocksPerLayer < Chunk.blocksPerLayer - Chunk.width {
      neighbouringIndices[.south] = (nil, indexInChunk + Chunk.width)
    } else {
      neighbouringIndices[.south] = (chunkDirection: .south, index: indexInChunk - Chunk.blocksPerLayer + Chunk.width)
    }
    
    if indexInChunk % Chunk.width != Chunk.width - 1 {
      neighbouringIndices[.east] = (nil, indexInChunk + 1)
    } else {
      neighbouringIndices[.east] = (chunkDirection: .east, index: indexInChunk - 15)
    }
    
    if indexInChunk % Chunk.width != 0 {
      neighbouringIndices[.west] = (nil, indexInChunk - 1)
    } else {
      neighbouringIndices[.west] = (chunkDirection: .west, index: indexInChunk + 15)
    }
    
    if indexInChunk < Chunk.numBlocks - Chunk.blocksPerLayer {
      neighbouringIndices[.up] = (nil, indexInChunk + Chunk.blocksPerLayer)
    }
    
    if indexInChunk >= Chunk.blocksPerLayer {
      neighbouringIndices[.down] = (nil, indexInChunk - Chunk.blocksPerLayer)
    }
    
    return neighbouringIndices
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
  
  /// Returns the sky light level for the block at the specified section-relative block index.
  func getSkyLightLevel(ofBlockAt index: Int) -> UInt8 {
    let neighbourIndices = getNeighbourIndices(ofBlockAt: index)
    var levels: [UInt8] = []
    for (_, neighbourBlock) in neighbourIndices {
      let level: UInt8?
      if let direction = neighbourBlock.chunkDirection {
        level = neighbourChunks[direction]?.lighting.getSkyLightLevel(atIndex: neighbourBlock.index)
      } else {
        level = chunk.lighting.getSkyLightLevel(atIndex: neighbourBlock.index)
      }
      levels.append(level ?? ChunkLighting.defaultSkyLightLevel)
    }
    
    // get light levels for top and bottom blocks in chunk
    let indexAdjustment = Chunk.Section.numBlocks - Chunk.blocksPerLayer
    if index < Chunk.blocksPerLayer && sectionPosition.sectionY == 0 {
      let lightIndex = index + indexAdjustment
      levels.append(chunk.lighting.getSkyLightLevel(atIndex: lightIndex, inSectionAt: -1))
    } else if index > indexAdjustment && sectionPosition.sectionY == (Chunk.numSections - 1) {
      let lightIndex = index - indexAdjustment
      levels.append(chunk.lighting.getSkyLightLevel(atIndex: lightIndex, inSectionAt: Chunk.numSections))
    }
    
    return levels.max() ?? 0
  }
  
  /// Generates a lookup table to quickly convert from section block index to block position.
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
