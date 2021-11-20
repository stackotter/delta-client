import Foundation

extension Chunk {
  /// A 16x16x16 section of a chunk. Just stores an array of block ids. Not thread-safe.
  public struct Section {
    /// The number of blocks wide a chunk section is (x axis).
    public static let width = Chunk.width
    /// The number of blocks tall a chunk section is (y axis).
    public static let height = Chunk.height / Chunk.numSections
    /// The number of blocks deep a chunk section is (z axis).
    public static let depth = Chunk.depth
    /// The number of blocks in a chunk section.
    public static let numBlocks = width * height * depth
    
    /// Block ids. Use Position.blockIndex to convert a position to an index in this array. The position must be relative to the section.
    public var blocks: [UInt16]
    /// The number of non-air blocks in the chunk section.
    public var blockCount: Int
    
    /// Whether the section is all air or not.
    public var isEmpty: Bool {
      blockCount == 0
    }
    
    /// Create an empty chunk section.
    public init() {
      blocks = [UInt16](repeating: 0, count: Section.numBlocks)
      blockCount = 0
    }
    
    /// Create a chunk section populated with blocks.
    /// - Parameters:
    ///   - blocks: An array of block ids with length `Section.width * Section.height * Section.depth`.
    ///   - blockCount: The number of non-air blocks in the array.
    public init(blocks: [UInt16], blockCount: Int) {
      self.blocks = blocks
      self.blockCount = blockCount
    }
    
    /// Create a chunk section populated with blocks.
    /// - Parameters:
    ///   - blockIds: Block ids or indices into the palette if the palette isn't empty.
    ///   - palette: Used as a look up table to convert palette ids to block ids. If empty, the palette is ignored.
    ///   - blockCount: The number of non-air blocks in the array.
    public init(blockIds: [UInt16], palette: [UInt16], blockCount: Int) {
      if !palette.isEmpty { // indirect palette
        self.blocks = blockIds.map {
          if $0 >= palette.count {
            log.warning("Indirect palette lookup failed: \($0) out of bounds for palette of length \(palette.count)")
            return 0
          }
          return palette[Int($0)]
        }
      } else {
        self.blocks = blockIds
      }
      self.blockCount = blockCount
    }
    
    /// Get the id of the block at the specified position.
    /// - Parameter position: Position of the block relative to this section.
    /// - Returns: The block id.
    ///
    /// For safety, the position is automatically converted to be relative to whatever section it is in. If
    /// you're using this in a performance critical loop perhaps you should manually access `blocks` instead.
    public func getBlockId(at position: Position) -> Int {
      let index = position.relativeToChunkSection.blockIndex
      return getBlockId(at: index)
    }
    
    /// Get the id of the block at the specified index in the section.
    /// - Parameter index: The index of the block relative to this section.
    /// - Returns: The block id, or `0` if the index is invalid
    public func getBlockId(at index: Int) -> Int {
      guard index < Section.numBlocks && index >= 0 else {
        log.warning("Invalid position passed to Chunk.Section.getBlockState(at:); index=\(index)")
        return 0
      }
      return Int(blocks[index])
    }
    
    /// Set the block id at the specified position.
    /// - Parameters:
    ///   - position: Position of the block relative to this section.
    ///   - id: The new block id.
    ///
    /// For safety, the position is automatically converted to be relative to whatever section it is in. If
    /// you're using this in a performance critical loop perhaps you should manually modify `blocks` instead.
    public mutating func setBlockId(at position: Position, to id: Int) {
      let index = position.relativeToChunkSection.blockIndex
      setBlockId(at: index, to: id)
    }
    
    /// Set the block id at the specified position.
    /// - Parameters:
    ///   - index: Index of the block relative to this section.
    ///   - id: The new block id.
    ///
    /// Does nothing if the block index is invalid.
    public mutating func setBlockId(at index: Int, to id: Int) {
      guard index < Section.numBlocks && index >= 0 else {
        log.warning("Invalid position passed to Chunk.Section.setBlockState(at:to:); index=\(index)")
        return
      }
      
      self.blocks[index] = UInt16(id)
      
      if Registry.shared.blockRegistry.isAir(getBlockId(at: index)) {
        blockCount += 1
      }
      
      if Registry.shared.blockRegistry.isAir(id) {
        blockCount -= 1
      }
    }
  }
}
