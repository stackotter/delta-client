import Foundation
import simd

/// A store for chunk lighting data. Not thread-safe.
///
/// It may also include lighting for the chunk sections above and below the world.
public struct ChunkLighting {
  // MARK: Public properties
  
  /// Sky light levels for each chunk section. Each array is indexed by block index.
  public private(set) var skyLightData: [Int: [UInt8]] = [:]
  /// Block light levels for each chunk section. Each array is indexed by block index.
  public private(set) var blockLightData: [Int: [UInt8]] = [:]
  
  /// Whether this lighting has been populated with initial data or not.
  public private(set) var isPopulated = false
  
  // MARK: Init
  
  /// Creates an empty chunk lighting store. ``isPopulated`` gets set to `false`.
  public init() {
    isPopulated = false
  }
  
  /// Creates a populated chunk lighting store.
  /// - Parameters:
  ///   - skyLightData: Sky lighting data for each chunk section in the chunk (possibly with a section above and below the world too).
  ///   - blockLightData: Block lighting data for each chunk section in the chunk (possibly with a section above and below the world too).
  public init(skyLightData: [Int: [UInt8]] = [:], blockLightData: [Int: [UInt8]] = [:]) {
    self.skyLightData = skyLightData
    self.blockLightData = blockLightData
    isPopulated = true
  }
  
  // MARK: Public methods
  
  /// Updates the lighting data with data received from the server.
  /// - Parameter data: The data received from the server.
  public mutating func update(with data: ChunkLightingUpdateData) {
    for index in data.emptySkyLightSections {
      skyLightData.removeValue(forKey: index)
    }
    
    for index in data.emptyBlockLightSections {
      blockLightData.removeValue(forKey: index)
    }
    
    for (index, array) in data.skyLightArrays {
      skyLightData[index] = array
    }
    
    for (index, array) in data.blockLightArrays {
      blockLightData[index] = array
    }
    
    isPopulated = true
  }
  
  /// Gets the light level at the given position. Includes both the block light and sky light level.
  /// - Parameter position: The position to get the light level at.
  /// - Returns: The requested light level. If the position is not loaded, the default light level is returned.
  public func getLightLevel(at position: BlockPosition) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(at: position)
    let blockLightLevel = getBlockLightLevel(at: position)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  /// Gets the light level at the given position. Includes both the block light and sky light level.
  /// - Parameters:
  ///   - position: The position to get the light level at (relative to the specified section).
  ///   - sectionIndex: The chunk section containing the light level to get.
  /// - Returns: The requested light level. If the position is not loaded, the default light level is returned.
  public func getLightLevel(at position: BlockPosition, inSectionAt sectionIndex: Int) -> LightLevel {
    var position = position
    position.y += sectionIndex * Chunk.Section.height
    let skyLightLevel = getSkyLightLevel(at: position)
    let blockLightLevel = getBlockLightLevel(at: position)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  /// Gets the light level at the given position. Includes both the block light and sky light level.
  /// - Parameters:
  ///   - index: The index of the block to get the light level for in the specified section.
  ///   - sectionIndex: The chunk section containing the light level to get.
  /// - Returns: The requested light level. If the position is not loaded, the default light level is returned.
  public func getLightLevel(atIndex index: Int, inSectionAt sectionIndex: Int) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(atIndex: index, inSectionAt: sectionIndex)
    let blockLightLevel = getBlockLightLevel(atIndex: index, inSectionAt: sectionIndex)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  /// Gets the light level at the given block index. Includes both the block light and sky light level.
  /// - Parameter index: The index of the block to get the light level for in the specified section.
  /// - Returns: The requested light level. If the position is not loaded, the default light level is returned.
  public func getLightLevel(at index: Int) -> LightLevel {
    let skyLightLevel = getSkyLightLevel(atIndex: index)
    let blockLightLevel = getBlockLightLevel(atIndex: index)
    return LightLevel(sky: skyLightLevel, block: blockLightLevel)
  }
  
  /// Gets the sky light level at the given position.
  /// - Parameter position: The position to get the light level at.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultSkyLightLevel`` is returned.
  public func getSkyLightLevel(at position: BlockPosition) -> Int {
    if !Self.isValidPosition(position) {
      return LightLevel.defaultSkyLightLevel
    }
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getSkyLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Gets the sky light level at the given position.
  /// - Parameter index: The index of the block to get the sky light level for in the specified section.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultSkyLightLevel`` is returned.
  public func getSkyLightLevel(atIndex blockIndex: Int) -> Int {
    if blockIndex < 0 || blockIndex >= Chunk.numBlocks {
      return LightLevel.defaultSkyLightLevel
    }
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getSkyLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Gets the sky light level at the given position.
  /// - Parameters:
  ///   - index: The index of the block to get the sky light level for in the specified section.
  ///   - sectionIndex: The chunk section containing the sky light level to get.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultSkyLightLevel`` is returned.
  public func getSkyLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> Int {
    if let skyLightArray = skyLightData[sectionIndex] {
      return Int(skyLightArray[blockIndex])
    } else {
      return LightLevel.defaultSkyLightLevel
    }
  }
  
  /// Gets the block light level at the given position.
  /// - Parameter position: The position to get the light level at.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultBlockLightLevel`` is returned.
  public func getBlockLightLevel(at position: BlockPosition) -> Int {
    if !Self.isValidPosition(position) {
      return LightLevel.defaultBlockLightLevel
    }
    let blockIndex = position.relativeToChunkSection.blockIndex
    return getBlockLightLevel(atIndex: blockIndex, inSectionAt: position.sectionIndex)
  }
  
  /// Gets the block light level at the given position.
  /// - Parameter index: The index of the block to get the block light level for in the specified section.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultBlockLightLevel`` is returned.
  public func getBlockLightLevel(atIndex blockIndex: Int) -> Int {
    if blockIndex < 0 || blockIndex >= Chunk.numBlocks {
      return LightLevel.defaultBlockLightLevel
    }
    let sectionRelativeBlockIndex = blockIndex % Chunk.Section.numBlocks
    let sectionIndex = blockIndex / Chunk.Section.numBlocks
    return getBlockLightLevel(atIndex: sectionRelativeBlockIndex, inSectionAt: sectionIndex)
  }
  
  /// Gets the block light level at the given position.
  /// - Parameters:
  ///   - index: The index of the block to get the block light level for in the specified section.
  ///   - sectionIndex: The chunk section containing the block light level to get.
  /// - Returns: The requested light level. If the position is not loaded, ``LightLevel/defaultBlockLightLevel`` is returned.
  public func getBlockLightLevel(atIndex blockIndex: Int, inSectionAt sectionIndex: Int) -> Int {
    if let blockLightArray = blockLightData[sectionIndex] {
      return Int(blockLightArray[blockIndex])
    } else {
      return LightLevel.defaultBlockLightLevel
    }
  }
  
  // TODO: Properly light sections when creating new ones
  
  /// Sets the block light level at the given position.
  /// - Parameters:
  ///   - position: The position to set the block light level for.
  ///   - newLevel: The new block light level from 0 to 15
  public mutating func setBlockLightLevel(at position: BlockPosition, to newLevel: Int) {
    guard Self.isValidPosition(position) else {
      return
    }
    
    let newLevel = MathUtil.clamp(newLevel, LightLevel.maximumLightLevel, 0)
    
    let sectionIndex = position.sectionIndex
    let blockIndex = position.relativeToChunkSection.blockIndex
    if blockLightData[sectionIndex] != nil {
      // It was done this way to prevent copies
      // swiftlint:disable force_unwrapping
      blockLightData[sectionIndex]![blockIndex] = UInt8(newLevel)
      // swiftlint:enable force_unwrapping
    } else {
      var blockLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultBlockLightLevel), count: Chunk.Section.numBlocks)
      let skyLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultSkyLightLevel), count: Chunk.Section.numBlocks)
      blockLighting[blockIndex] = UInt8(newLevel)
      blockLightData[sectionIndex] = blockLighting
      skyLightData[sectionIndex] = skyLighting
    }
  }
  
  /// Sets the sky light level at the given position.
  /// - Parameters:
  ///   - position: The position to set the sky light level for.
  ///   - newLevel: The new sky light level from 0 to 15
  public mutating func setSkyLightLevel(at position: BlockPosition, to newLevel: Int) {
    guard Self.isValidPosition(position) else {
      return
    }
    
    let newLevel = MathUtil.clamp(newLevel, LightLevel.maximumLightLevel, 0)
    
    let sectionIndex = position.sectionIndex
    let blockIndex = position.relativeToChunkSection.blockIndex
    if skyLightData[sectionIndex] != nil {
      // It was done this way to prevent copies
      // swiftlint:disable force_unwrapping
      skyLightData[sectionIndex]![blockIndex] = UInt8(newLevel)
      // swiftlint:enable force_unwrapping
    } else {
      let blockLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultBlockLightLevel), count: Chunk.Section.numBlocks)
      var skyLighting: [UInt8] = [UInt8](repeating: UInt8(LightLevel.defaultSkyLightLevel), count: Chunk.Section.numBlocks)
      skyLighting[blockIndex] = UInt8(newLevel)
      blockLightData[sectionIndex] = blockLighting
      skyLightData[sectionIndex] = skyLighting
    }
  }
  
  // MARK: Private methods
  
  /// Checks whether a position is within the chunk (including 1 block above and below).
  /// - Parameter position: The position to check.
  /// - Returns: Whether the position is valid or not.
  private static func isValidPosition(_ position: BlockPosition) -> Bool {
    return position.x >= 0 && position.y >= -1 && position.z >= 0 && position.x < Chunk.width && position.y < Chunk.height + 1 && position.z < Chunk.depth
  }
}
