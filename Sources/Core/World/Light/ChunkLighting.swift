import Foundation
import simd

/// An object for storing and accessing chunk lighting data.
public struct ChunkLighting {
  /// Sky light levels for each chunk section. Each array is indexed by block index.
  public private(set) var skyLightData: [Int: [UInt8]] = [:]
  /// Block light levels for each chunk section. Each array is indexed by block index.
  public private(set) var blockLightData: [Int: [UInt8]] = [:]
  
  /// Whether this lighting has been populated with initial data or not.
  public private(set) var isPopulated = false
  
  public init() {
    isPopulated = false
  }
  
  public init(skyLightData: [Int : [UInt8]] = [:], blockLightData: [Int : [UInt8]] = [:]) {
    self.skyLightData = skyLightData
    self.blockLightData = blockLightData
    isPopulated = true
  }
  
  /// Gets a list of sections present based on a bitmask.
  private static func sectionsPresent(in bitmask: Int) -> [Int] {
    var present = BinaryUtil.setBits(of: bitmask, n: Chunk.numSections + 2)
    present = present.map { $0 - 1 }
    return present
  }
  
  /// Updates the lighting data with data received from the server.
  public mutating func update(with data: ChunkLightingUpdateData) {
    for (index, array) in data.skyLightArrays {
      skyLightData[index] = array
    }
    
    for (index, array) in data.blockLightArrays {
      blockLightData[index] = array
    }
    
    for index in data.emptySkyLightSections {
      skyLightData.removeValue(forKey: index)
    }
    
    for index in data.emptyBlockLightSections {
      blockLightData.removeValue(forKey: index)
    }
    
    isPopulated = true
  }
  
  public func getLightLevel(at position: Position) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(at: position)
    let blockLightLevel = getBlockLightLevel(at: position)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  public func getLightLevel(at position: Position, inSectionAt sectionIndex: Int) -> LightLevel {
    var position = position
    position.y += sectionIndex * Chunk.Section.height
    let skyLightLevel = getSkyLightLevel(at: position)
    let blockLightLevel = getBlockLightLevel(at: position)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  public func getLightLevel(atIndex index: Int, inSectionAt sectionIndex: Int) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(atIndex: index, inSectionAt: sectionIndex)
    let blockLightLevel = getBlockLightLevel(atIndex: index, inSectionAt: sectionIndex)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  public func getLightLevel(at index: Int) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(atIndex: index)
    let blockLightLevel = getBlockLightLevel(atIndex: index)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  /// Returns the sky light level at the specified position.
  public func getSkyLightLevel(at position: Position) -> Int {
    if !Self.isValidPosition(position) {
      return LightLevel.defaultSkyLightLevel
    }
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getSkyLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Returns the sky light level at the specified chunk-relative block index.
  public func getSkyLightLevel(atIndex blockIndex: Int) -> Int {
    if blockIndex < 0 || blockIndex >= Chunk.numBlocks {
      return LightLevel.defaultSkyLightLevel
    }
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getSkyLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Returns the sky light level at the specified section-relative block index in the specified chunk section.
  public func getSkyLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> Int {
    if let skyLightArray = skyLightData[sectionIndex] {
      return Int(skyLightArray[blockIndex])
    } else {
      return LightLevel.defaultSkyLightLevel
    }
  }
  
  /// Returns the block light level at the specified position.
  public func getBlockLightLevel(at position: Position) -> Int {
    if !Self.isValidPosition(position) {
      return LightLevel.defaultBlockLightLevel
    }
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getBlockLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Returns the block light level at the specified chunk-relative block index.
  public func getBlockLightLevel(atIndex blockIndex: Int) -> Int {
    if blockIndex < 0 || blockIndex >= Chunk.numBlocks {
      return LightLevel.defaultBlockLightLevel
    }
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getBlockLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Returns the block light level at the specified section-relative block index in the specified chunk section.
  public func getBlockLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> Int {
    if let blockLightArray = blockLightData[sectionIndex] {
      return Int(blockLightArray[blockIndex])
    } else {
      return LightLevel.defaultBlockLightLevel
    }
  }
  
  // TODO: properly initialise sky light sections when creating new ones
  
  public mutating func setBlockLightLevel(at position: Position, to newLevel: Int) {
    guard Self.isValidPosition(position) else {
      return
    }
    
    let sectionIndex = position.sectionIndex
    let blockIndex = position.relativeToChunkSection.blockIndex
    if blockLightData[sectionIndex] != nil {
      blockLightData[sectionIndex]![blockIndex] = UInt8(newLevel)
    } else {
      var blockLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultBlockLightLevel), count: Chunk.Section.numBlocks)
      let skyLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultSkyLightLevel), count: Chunk.Section.numBlocks)
      blockLighting[blockIndex] = UInt8(newLevel)
      blockLightData[sectionIndex] = blockLighting
      skyLightData[sectionIndex] = skyLighting
    }
  }
  
  public mutating func setSkyLightLevel(at position: Position, to newLevel: Int) {
    guard Self.isValidPosition(position) else {
      return
    }
    
    let sectionIndex = position.sectionIndex
    let blockIndex = position.relativeToChunkSection.blockIndex
    if skyLightData[sectionIndex] != nil {
      skyLightData[sectionIndex]![blockIndex] = UInt8(newLevel)
    } else {
      let blockLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultBlockLightLevel), count: Chunk.Section.numBlocks)
      var skyLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultSkyLightLevel), count: Chunk.Section.numBlocks)
      skyLighting[blockIndex] = UInt8(newLevel)
      blockLightData[sectionIndex] = blockLighting
      skyLightData[sectionIndex] = skyLighting
    }
  }
  
  public static func isValidPosition(_ position: Position) -> Bool {
    return position.x >= 0 && position.y >= 0 && position.z >= 0 && position.x < Chunk.width && position.y < Chunk.height && position.z < Chunk.depth
  }
}
