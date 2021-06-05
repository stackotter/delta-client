//
//  Chunk.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

class Chunk {
  // constants
  static let width = 16
  static let depth = 16
  static let height = 256
  static let blocksPerLayer = width * depth
  static let numBlocks = height * blocksPerLayer
  static let numSections = 16
  
  // chunk data
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var blockEntities: [BlockEntity]
  var sections: [Chunk.Section]
  
  var stopwatch = Stopwatch(mode: .summary, name: "chunk")
  
  // in the format that it is received
  var biomes: [UInt8]
  
  init(
    heightMaps: NBTCompound,
    ignoreOldData: Bool,
    biomes: [UInt8],
    sections: [Chunk.Section],
    blockEntities: [BlockEntity])
  {
    self.heightMaps = heightMaps
    self.ignoreOldData = ignoreOldData
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
      Logger.trace("Ignoring attempt to set block to state it's already in")
      return
    }
    
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    sections[sectionIndex].setBlockState(at: sectionBlockIndex, to: newState)
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
  
  // get which faces of block are against non-air neighbours
  func getNonAirNeighbours(ofBlockAt index: Int) -> [FaceDirection: Int] {
    var presentNeighbours = getNeighbouringIndices(for: index)
    for (direction, index) in presentNeighbours where getBlock(at: index) == 0 {
      presentNeighbours.removeValue(forKey: direction)
    }
    
    return presentNeighbours
  }
}
