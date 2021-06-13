//
//  Chunk.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

class Chunk {
  static let width = 16
  static let depth = 16
  static let height = 256
  static let blocksPerLayer = width * depth
  static let numBlocks = height * blocksPerLayer
  static let numSections = 16
  
  /// No-one really knows what this is for. Vanilla servers just send it.
  var heightMaps: NBTCompound
  /// Block entities for this chunk (i.e. chests, beds etc.)
  var blockEntities: [BlockEntity]
  /// Block states are stored in chunk sections corresponding to 16x16x16 divisions of the chunk from lowest to highest.
  var sections: [Chunk.Section]
  
  /// 3d biome data in 4x4x4 blocks.
  var biomes: [UInt8] // in the format that it is received
  /// Lighting data that is populated once UpdateLightPacket is receive for this chunk.
  var lighting = ChunkLighting()
  
  init(
    heightMaps: NBTCompound,
    biomes: [UInt8],
    sections: [Chunk.Section],
    blockEntities: [BlockEntity]
  ) {
    self.heightMaps = heightMaps
    self.biomes = biomes
    self.sections = sections
    self.blockEntities = blockEntities
  }
  
  func getBlock(at position: Position) -> UInt16 {
    let blockIndex = position.blockIndex
    return getBlock(at: blockIndex)
  }
  
  func getBlock(at index: Int) -> UInt16 {
    assert(
      isValidBlockIndex(index),
      "Invalid block index passed to Chunk.getBlock(at:), index=\(index)")
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    return sections[sectionIndex].getBlockState(at: sectionBlockIndex)
  }
  
  func setBlock(at position: Position, to newState: UInt16) {
    let blockIndex = position.blockIndex
    setBlock(at: blockIndex, to: newState)
  }
  
  func setBlock(at index: Int, to newState: UInt16) {
    assert(
      isValidBlockIndex(index),
      "Invalid block index passed to Chunk.setBlock(at:to:), index=\(index)")
    
    if getBlock(at: index) == newState {
      log.trace("Ignoring attempt to set block to state it's already in")
      return
    }
    
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    sections[sectionIndex].setBlockState(at: sectionBlockIndex, to: newState)
  }
  
  func setSection(atIndex index: Int, to section: Section) {
    sections[index] = section
  }
  
  func isValidBlockIndex(_ index: Int) -> Bool {
    return index >= 0 && index < Chunk.numBlocks
  }
  
  func isValidBlockPosition(_ position: Position) -> Bool {
    return (
      position.x < Chunk.width && position.x >= 0 &&
      position.z < Chunk.depth && position.z >= 0 &&
      position.y < Chunk.height && position.y >= 0)
  }
  
  /// Gets the indices of the blocks in this chunk that neighbour the block at `index`
  func getNeighbouringIndices(for index: Int) -> [FaceDirection: Int] {
    // TODO: remove get_neighbouring_blocks c function
    var neighbouringBlocks: [FaceDirection: Int] = [:]
    
    if index % Chunk.blocksPerLayer >= Chunk.width {
      neighbouringBlocks[.north] = index - Chunk.width
    }
    
    if index % Chunk.blocksPerLayer < Chunk.blocksPerLayer - Chunk.width {
      neighbouringBlocks[.south] = index + Chunk.width
    }
    
    if index % Chunk.width != Chunk.width - 1 {
      neighbouringBlocks[.east] = index + 1
    }
    
    if index % Chunk.width != 0 {
      neighbouringBlocks[.west] = index - 1
    }
    
    if index < Chunk.numBlocks - Chunk.blocksPerLayer {
      neighbouringBlocks[.up] = index + Chunk.blocksPerLayer
    }
    
    if index >= Chunk.blocksPerLayer {
      neighbouringBlocks[.down] = index - Chunk.blocksPerLayer
    }
    
    return neighbouringBlocks
  }
  
  /// Gets the indices of all non-air blocks in chunk that neighbour the block at `index`
  func getNonAirNeighbours(ofBlockAt index: Int) -> [FaceDirection: Int] {
    var nonAirNeighbours = getNeighbouringIndices(for: index)
    for (direction, index) in nonAirNeighbours where getBlock(at: index) == 0 {
      nonAirNeighbours.removeValue(forKey: direction)
    }
    
    return nonAirNeighbours
  }
}
