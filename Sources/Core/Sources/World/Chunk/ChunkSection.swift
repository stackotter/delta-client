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
    ///   - blocks: An array of block ids. Length must be equal to ``numBlocks``.
    ///   - blockCount: The number of non-air blocks in the array.
    public init(blocks: [UInt16], blockCount: Int) {
      assert(blocks.count == Self.numBlocks, "Attempted to initialize Chunk.Section with \(blocks.count) blocks but it must have \(Self.numBlocks) blocks")

      self.blocks = blocks
      self.blockCount = blockCount
    }

    /// Create a chunk section populated with blocks.
    /// - Parameters:
    ///   - blockIds: Block ids or indices into the palette if the palette isn't empty. Length must be equal to ``numBlocks``.
    ///   - palette: Used as a look up table to convert palette ids to block ids. If empty, the palette is ignored.
    ///   - blockCount: The number of non-air blocks in the array.
    public init(blockIds: [UInt16], palette: [UInt16], blockCount: Int) {
      assert(blockIds.count == Self.numBlocks, "Attempted to initialize Chunk.Section with \(blockIds.count) blocks but it must have \(Self.numBlocks) blocks")

      self.blocks = []
      blocks.reserveCapacity(blockIds.count)

      self.blockCount = blockCount

      // See https://wiki.vg/Chunk_Format
      if !palette.isEmpty {
        for blockId in blockIds {
          if blockId >= palette.count {
            log.warning("Indirect palette lookup failed: block id \(blockId) out of bounds for palette of length \(palette.count), defaulting to 0 (air)")
            blocks.append(0)
            continue
          }
          blocks.append(palette[Int(blockId)])
        }
      } else {
        self.blocks = blockIds
      }
    }

    /// Get the id of the block at the specified position.
    /// - Parameter position: Position of the block relative to this section.
    /// - Returns: The block id.
    ///
    /// For safety, the position is automatically converted to be relative to whatever section it is in. If
    /// you're using this in a performance critical loop perhaps you should manually access ``blocks`` instead.
    public func getBlockId(at position: BlockPosition) -> Int {
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
    /// you're using this in a performance critical loop perhaps you should manually modify ``blocks`` instead.
    public mutating func setBlockId(at position: BlockPosition, to id: Int) {
      let index = position.relativeToChunkSection.blockIndex
      setBlockId(at: index, to: id)
    }

    /// Set the block id at the specified position. Does nothing if the block index is invalid.
    /// - Parameters:
    ///   - index: Index of the block relative to this section.
    ///   - id: The new block id.
    public mutating func setBlockId(at index: Int, to id: Int) {
      guard index < Section.numBlocks && index >= 0 else {
        log.warning("Invalid position passed to Chunk.Section.setBlockId(at:to:); index=\(index)")
        return
      }

      if RegistryStore.shared.blockRegistry.isAir(Int(blocks[index])) {
        blockCount += 1
      }

      if RegistryStore.shared.blockRegistry.isAir(id) {
        blockCount -= 1
      }

      blocks[index] = UInt16(id)
    }
  }
}
