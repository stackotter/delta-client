import Foundation

public final class Chunk {
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
  
  /// Block entities for this chunk (i.e. chests, beds etc.)
  public var blockEntities: [BlockEntity]
  /// Blocks are stored in chunk sections corresponding to 16x16x16 sections of the chunk from lowest to highest.
  public var sections: [Chunk.Section]
  
  /// 3d biome data in 4x4x4 blocks.
  public var biomes: [UInt8] // In the format that it is received
  /// Lighting data that is populated once UpdateLightPacket is receive for this chunk.
  public var lighting = ChunkLighting()
  
  public var heightMap: HeightMap
  
  private var blockRegistry: BlockRegistry
  
  /// Creates a new chunk from the data contained within a chunk data packet.
  public init(_ packet: ChunkDataPacket, blockRegistry: BlockRegistry) {
    self.heightMap = packet.heightMap
    self.blockEntities = packet.blockEntities
    self.sections = packet.sections
    self.biomes = packet.biomes
    self.blockRegistry = blockRegistry
  }
  
  public func getBlock(at position: Position) -> Block {
    let stateId = Int(getBlockStateId(at: position))
    return blockRegistry.getBlockForState(withId: stateId) ?? Block.missing
  }
  
  public func getBlockState(at position: Position) -> BlockState {
    let stateId = Int(getBlockStateId(at: position))
    return blockRegistry.getBlockState(withId: stateId) ?? BlockState.missing
  }
  
  public func getBlockStateId(at position: Position) -> UInt16 {
    let blockIndex = position.blockIndex
    return getBlockStateId(at: blockIndex)
  }
  
  public func getBlockStateId(at index: Int) -> UInt16 {
    assert(
      Self.isValidBlockIndex(index),
      "Invalid block index passed to Chunk.getBlockStateId(at:), index=\(index)")
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    return sections[sectionIndex].getBlockState(at: sectionBlockIndex)
  }
  
  /// Set the specified block to the specified state. Updates the height map. DOES NOT UPDATE LIGHTING.
  public func setBlockStateId(at position: Position, to newState: UInt16) {
    let blockIndex = position.blockIndex
    let sectionIndex = blockIndex / Section.numBlocks
    let sectionBlockIndex = blockIndex % Section.numBlocks
    sections[sectionIndex].setBlockState(at: sectionBlockIndex, to: newState)
    
    heightMap.handleBlockUpdate(at: position, in: self)
  }
  
  /// Updates the chunk with data sent from the server.
  public func update(with packet: ChunkDataPacket) {
    blockEntities = packet.blockEntities
    heightMap = packet.heightMap
    for sectionIndex in packet.presentSections {
      setSection(atIndex: sectionIndex, to: packet.sections[sectionIndex])
    }
  }
  
  public func setSection(atIndex index: Int, to section: Section) {
    sections[index] = section
  }
  
  public static func isValidBlockIndex(_ index: Int) -> Bool {
    return index >= 0 && index < Chunk.numBlocks
  }
  
  public static func isValidBlockPosition(_ position: Position) -> Bool {
    return (
      position.x < Chunk.width && position.x >= 0 &&
      position.z < Chunk.depth && position.z >= 0 &&
      position.y < Chunk.height && position.y >= 0)
  }
}
