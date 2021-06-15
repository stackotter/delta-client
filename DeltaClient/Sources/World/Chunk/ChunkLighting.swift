//
//  ChunkLighting.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 17/4/21.
//

import Foundation

/// An object for storing and accessing chunk lighting data.
class ChunkLighting {
  static var defaultSkyLightLevel: UInt8 = 0
  static var defaultBlockLightLevel: UInt8 = 0
  
  var skyLightData: [Int: [UInt8]] = [:]
  var blockLightData: [Int: [UInt8]] = [:]
  
  var isPopulated = false
  
  /// Gets a list of sections present based on a bitmask.
  private static func sectionsPresent(in bitmask: Int) -> [Int] {
    var present = BinaryUtil.setBits(of: bitmask, n: Chunk.numSections + 2)
    present = present.map { $0 - 1 }
    return present
  }
  
  /// Updates the lighting data with data received from the server.
  func update(with data: ChunkLightingUpdateData) {
    let skyLightIndices = ChunkLighting.sectionsPresent(in: data.skyLightMask)
    let blockLightIndices = ChunkLighting.sectionsPresent(in: data.blockLightMask)
    let emptySkyLightIndices = ChunkLighting.sectionsPresent(in: data.emptySkyLightMask)
    let emptyBlockLightIndices = ChunkLighting.sectionsPresent(in: data.emptyBlockLightMask)
    
    guard skyLightIndices.count == data.skyLightArrays.count else {
      let bitsSet = skyLightIndices.count
      let sectionsReceived = data.skyLightArrays.count
      log.error("Invalid sky light mask sent. \(bitsSet) bits set but \(sectionsReceived) sections received")
      return
    }
    
    guard blockLightIndices.count == data.blockLightArrays.count else {
      let bitsSet = blockLightIndices.count
      let sectionsReceived = data.blockLightArrays.count
      log.error("Invalid block light mask sent. \(bitsSet) bits set but \(sectionsReceived) sections received")
      return
    }
    
    skyLightIndices.enumerated().forEach { index, sectionIndex in
      updateSectionSkyLight(with: data.skyLightArrays[index], for: sectionIndex)
    }
    
    blockLightIndices.enumerated().forEach { index, sectionIndex in
      updateSectionBlockLight(with: data.blockLightArrays[index], for: sectionIndex)
    }
    
    emptySkyLightIndices.forEach { sectionIndex in
      removeSectionSkyLight(for: sectionIndex)
    }
    
    emptyBlockLightIndices.forEach { sectionIndex in
      removeSectionBlockLight(for: sectionIndex)
    }
    
    isPopulated = true
  }
  
  /// Updates sky lighting data for the specified section.
  private func updateSectionSkyLight(with data: [UInt8], for sectionIndex: Int) {
    skyLightData[sectionIndex] = data
  }
  
  /// Updates block lighting data for the specified section.
  private func updateSectionBlockLight(with data: [UInt8], for sectionIndex: Int) {
    blockLightData[sectionIndex] = data
  }
  
  /// Removes sky lighting data for the specified section.
  private func removeSectionSkyLight(for sectionIndex: Int) {
    skyLightData.removeValue(forKey: sectionIndex)
  }
  
  /// Removes block lighting data for the specified section.
  private func removeSectionBlockLight(for sectionIndex: Int) {
    blockLightData.removeValue(forKey: sectionIndex)
  }
  
  /// Returns the sky light level at the specified position.
  func getSkyLightLevel(at position: Position) -> UInt8 {
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getSkyLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Returns the sky light level at the specified chunk-relative block index.
  func getSkyLightLevel(atIndex blockIndex: Int) -> UInt8 {
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getSkyLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Returns the sky light level at the specified section-relative block index in the specified chunk section.
  func getSkyLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> UInt8 {
    if let skyLightArray = skyLightData[sectionIndex] {
      let compactValue = skyLightArray[blockIndex >> 1]
      let level: UInt8
      if blockIndex & 0x1 == 0x0 { // even
        level = compactValue & 0xf
      } else { // odd
        level = compactValue >> 4
      }
      return level
    } else {
      return ChunkLighting.defaultSkyLightLevel
    }
  }
  
  /// Returns the block light level at the specified position.
  func getBlockLightLevel(at position: Position) -> UInt8 {
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getBlockLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Returns the block light level at the specified chunk-relative block index.
  func getBlockLightLevel(atIndex blockIndex: Int) -> UInt8 {
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getBlockLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Returns the block light level at the specified section-relative block index in the specified chunk section.
  func getBlockLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> UInt8 {
    if let blockLightArray = blockLightData[sectionIndex] {
      let compactValue = blockLightArray[blockIndex >> 1]
      let level: UInt8
      if blockIndex & 0x1 == 0x0 { // even
        level = compactValue & 0xf
      } else { // odd
        level = compactValue >> 4
      }
      return level
    } else {
      return ChunkLighting.defaultBlockLightLevel
    }
  }
}
