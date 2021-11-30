import Foundation

/// Holds data about a chunk.
///
/// Sometimes referred to as a chunk column online. It is a column of ``Chunk.Section``s with
/// some extra information about block entities, biomes, lighting and heightmaps.
public final class Chunk {
  // MARK: Constants
  
  /// The width of a chunk in the x direction.
  public static let width = 16
  /// The width of a chunk in the z direction.
  public static let depth = 16
  /// The height of a chunk in the y direction.
  public static let height = 256
  /// The number of blocks in each 1 block tall layer of a chunk.
  public static let blocksPerLayer = width * depth
  /// The total number of blocks per chunk.
  public static let numBlocks = height * blocksPerLayer
  /// The total number of sections per chunk.
  public static let numSections = 16
  
  // MARK: Chunk data
  
  /// Blocks are stored in chunk sections corresponding to 16x16x16 sections of the chunk from lowest to highest.
  public var sections: [Chunk.Section]
  /// Block entities for this chunk (i.e. chests, beds etc.)
  public var blockEntities: [BlockEntity]
  
  /// 3d biome data in 4x4x4 blocks.
  public var biomeIds: [UInt8]
  /// Lighting data that is populated once UpdateLightPacket is receive for this chunk.
  public var lighting = ChunkLighting()
  /// Information about the highest blocks in each column of the chunk.
  public var heightMap: HeightMap
  
  // MARK: Init
  
  /// Creates a new chunk
  /// - Parameters:
  ///   - sections: An array of 16 chunk sections from lowest to highest.
  ///   - blockEntities: An array of block entities in the chunk in no particular order.
  ///   - biomeIds: The biomes of the chunk in 4x4x4 blocks. Indexed in the same order as blocks. (Index is block index divided by 4).
  ///   - lighting: Lighting data for the chunk
  ///   - heightMap: Information about the highest blocks in each column of the chunk.
  public init(sections: [Chunk.Section], blockEntities: [BlockEntity], biomeIds: [UInt8], lighting: ChunkLighting? = nil, heightMap: HeightMap) {
    self.sections = sections
    self.blockEntities = blockEntities
    self.biomeIds = biomeIds
    self.lighting = lighting ?? ChunkLighting()
    self.heightMap = heightMap
  }
  
  /// Creates a new chunk from the data contained within a chunk data packet.
  public init(_ packet: ChunkDataPacket) {
    self.heightMap = packet.heightMap
    self.blockEntities = packet.blockEntities
    self.sections = packet.sections
    self.biomeIds = packet.biomeIds
  }
  
  // MARK: Blocks
  
  /// Get information about a block.
  /// - Parameter position: A block position relative to the chunk.
  /// - Returns: Information about block and its state. Returns ``Block.missing`` if block state id is invalid.
  public func getBlock(at position: Position) -> Block {
    let stateId = getBlockId(at: position)
    return RegistryStore.shared.blockRegistry.block(withId: stateId) ?? Block.missing
  }
  
  /// Get the block state id of the block at a position.
  /// - Parameter position: A block position relative to the chunk.
  /// - Returns: Block id of block. Returns 0 (regular air) if `position` is invalid (outside chunk).
  public func getBlockId(at position: Position) -> Int {
    let blockIndex = position.blockIndex
    return getBlockId(at: blockIndex)
  }
  
  /// Get the block state id of the block at an index.
  /// - Parameter index: Can be obtained using ``Position.blockIndex``. Relative to the chunk.
  /// - Returns: Block id of block. Returns 0 (air) if `index` is invalid (outside chunk).
  public func getBlockId(at index: Int) -> Int {
    if !Self.isValidBlockIndex(index) {
      log.warning("Invalid block index passed to Chunk.getBlockStateId(at:), index=\(index), returning block id 0 (air)")
      return 0
    }
    
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    return sections[sectionIndex].getBlockId(at: sectionBlockIndex)
  }
  
  /// Sets the block at the given position to a new value.
  ///
  /// Updates the height map. **Does not update lighting**.
  ///
  /// - Parameters:
  ///   - position: A position relative to the chunk.
  ///   - newState: A new block state. Not validated.
  public func setBlockId(at position: Position, to state: Int) {
    // TODO: Validate block state
    let blockIndex = position.blockIndex
    let sectionIndex = blockIndex / Section.numBlocks
    let sectionBlockIndex = blockIndex % Section.numBlocks
    sections[sectionIndex].setBlockId(at: sectionBlockIndex, to: state)
    
    heightMap.handleBlockUpdate(at: position, in: self)
  }
  
  // MARK: Biomes
  
  /// Get the biome of the block at the given position.
  /// - Parameter position: Position of block in chunk relative coordinates.
  /// - Returns: Data about the biome.
  public func biomeId(at position: Position) -> Int {
    let index = position.biomeIndex
    return Int(biomeIds[index])
  }
  
  /// Get the biome of the block at the given position.
  /// - Parameter position: Position of block in chunk relative coordinates.
  /// - Returns: Data about the biome.
  public func biome(at position: Position) -> Biome? {
    let biomeId = self.biomeId(at: position)
    return RegistryStore.shared.biomeRegistry.biome(withId: biomeId)
  }
  
  // MARK: Sections
  
  /// Updates the chunk with data sent from the server.
  public func update(with packet: ChunkDataPacket) {
    blockEntities = packet.blockEntities
    heightMap = packet.heightMap
    for sectionIndex in packet.presentSections {
      setSection(atIndex: sectionIndex, to: packet.sections[sectionIndex])
    }
  }
  
  /// Replaces a section with a new one.
  /// - Parameters:
  ///   - index: A section index (from 0 to 15 inclusive). Not validated.
  ///   - section: The replacement section.
  public func setSection(atIndex index: Int, to section: Section) {
    sections[index] = section
  }
  
  // MARK: Helper
  
  /// - Returns: `true` if the block index is contained within a chunk.
  public static func isValidBlockIndex(_ index: Int) -> Bool {
    return index >= 0 && index < Chunk.numBlocks
  }
  
  /// - Returns: `true` if the block position is contained within the a chunk.
  public static func isValidBlockPosition(_ position: Position) -> Bool {
    return (
      position.x < Chunk.width && position.x >= 0 &&
      position.z < Chunk.depth && position.z >= 0 &&
      position.y < Chunk.height && position.y >= 0)
  }
}
