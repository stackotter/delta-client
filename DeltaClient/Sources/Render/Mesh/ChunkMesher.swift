//
//  ChunkMesher.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation

struct ChunkMesher {
  // allows for faster conversion from index to position
  static var indexToPosition = ChunkMesher.generateIndexLookup()
  
  var chunk: Chunk
  var chunkPosition: ChunkPosition
  var neighbourChunks: [CardinalDirection: Chunk]
  
  private var blockPaletteManager: BlockPaletteManager
  private var blockIndexToElementId: [Int: [Int]] = [:]
  
  init(
    for chunk: Chunk,
    at chunkPosition: ChunkPosition,
    withNeighbours neighbourChunks: [CardinalDirection: Chunk],
    blockPaletteManager: BlockPaletteManager)
  {
    self.chunk = chunk
    self.chunkPosition = chunkPosition
    self.neighbourChunks = neighbourChunks
    self.blockPaletteManager = blockPaletteManager
  }
  
  /// Adds all blocks in `chunk` to `mesh` at `chunkPosition`
  mutating func prepare(into mesh: ElementMesh) {
    // add blocks to mesh
    chunk.sections.enumerated().forEach { sectionIndex, section in
      if section.blockCount != 0 {
        let startTime = CFAbsoluteTimeGetCurrent()
        let sectionY = sectionIndex * 16
        for sectionBlockIndex in 0..<Chunk.Section.numBlocks {
          let blockState = section.getBlockState(at: sectionBlockIndex)
          if blockState != 0 {
            var position = ChunkMesher.indexToPosition[sectionBlockIndex]
            position.y += sectionY
            if let blockModel = blockPaletteManager.getVariant(for: blockState, at: position) {
              add(blockModel, to: mesh, at: position)
            }
          }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.info("completed chunk section in \(elapsed) seconds with \(section.blockCount) blocks")
      }
    }
    
    // make sure buffers are regenerated
    mesh.hasChanged = true
  }
  
  mutating func replaceBlock(at position: Position, in mesh: ElementMesh, with blockState: UInt16, shouldUpdateNeighbours: Bool = true) {
    let blockIndex = position.blockIndex
    if let elementIds = blockIndexToElementId.removeValue(forKey: blockIndex) {
      elementIds.forEach { elementId in
        mesh.removeBlockModelElement(elementId)
      }
    }
    if let blockModel = blockPaletteManager.getVariant(for: blockState, at: position) {
      add(blockModel, to: mesh, at: position)
    } else {
      Logger.warn(
        "Failed to update block to state=\(blockState) in ElementMesh at \(position) in chunk at \(chunkPosition)")
    }
    
    if shouldUpdateNeighbours {
      updateNeighbours(ofBlockAt: position, in: mesh)
    }
    
    mesh.hasChanged = true
  }
  
  private mutating func updateNeighbours(ofBlockAt position: Position, in mesh: ElementMesh) {
    let blockIndex = position.blockIndex
    let nonAirNeighbours = chunk.getNonAirNeighbours(ofBlockAt: blockIndex)
    nonAirNeighbours.forEach { _, neighbourBlockIndex in
      let neighbourBlockState = chunk.getBlock(at: neighbourBlockIndex)
      var neighbourBlockPosition = ChunkMesher.indexToPosition[neighbourBlockIndex % 4096]
      neighbourBlockPosition.y += neighbourBlockIndex / Chunk.blocksPerLayer
      replaceBlock(at: neighbourBlockPosition, in: mesh, with: neighbourBlockState, shouldUpdateNeighbours: false)
    }
  }
  
  /// Adds `blockModel` to `mesh` at `position`
  private mutating func add(_ blockModel: BlockModel, to mesh: ElementMesh, at position: Position) {
    let blockIndex = position.blockIndex
    
    let neighbourBlockStates = getNeighbourBlockStates(ofBlockAt: blockIndex)
    var cullingNeighbours: Set<FaceDirection> = []
    for (direction, neighbourBlockState) in neighbourBlockStates where neighbourBlockState != 0 {
      if let blockModel = blockPaletteManager.getVariant(for: neighbourBlockState, at: position) {
        if blockModel.fullFaces.contains(direction.opposite) {
          cullingNeighbours.insert(direction)
        }
      }
    }
    
    var elementIds: [Int] = []
    blockModel.elements.forEach { element in
      let elementId = mesh.addBlockModelElement(element, at: position, culling: cullingNeighbours)
      elementIds.append(elementId)
    }
    
    blockIndexToElementId[blockIndex] = elementIds
  }
  
  /// Gets the block states of the blocks neighbouring the block at `index`
  private func getNeighbourBlockStates(ofBlockAt index: Int) -> [FaceDirection: UInt16] {
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
