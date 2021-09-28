import Foundation

extension Chunk {
  public struct Section {
    public static let width = Chunk.width
    public static let height = Chunk.height / Chunk.numSections
    public static let depth = Chunk.depth
    public static let numBlocks = width * height * depth
    
    public var blocks = [UInt16](repeating: 0, count: Section.numBlocks)
    public var blockCount: Int16 = 0
    
    public init() { } // used for empty chunks
    
    public init(blocks: [UInt16], blockCount: Int16) {
      self.blocks = blocks
      self.blockCount = blockCount
    }
    
    public init(blockIds: [UInt16], palette: [UInt16], blockCount: Int16) {
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
    
    public func getBlockState(at position: Position) -> UInt16 {
      let index = position.blockIndex
      return getBlockState(at: index)
    }
    
    public func getBlockState(at index: Int) -> UInt16 {
      assert(index < Section.numBlocks && index >= 0, "Invalid position passed to Chunk.Section.getBlockState(at:)")
      return blocks[index]
    }
    
    public mutating func setBlockState(at position: Position, to newState: UInt16) {
      let index = position.blockIndex
      setBlockState(at: index, to: newState)
    }
    
    public mutating func setBlockState(at index: Int, to newState: UInt16) {
      assert(index < Section.numBlocks && index >= 0, "Invalid position passed to Chunk.Section.setBlockState(at:to:)")
      self.blocks[index] = newState
      
      if getBlockState(at: index) == 0 {
        blockCount += 1
      }
      
      if newState == 0 {
        blockCount -= 1
      }
    }
  }
}
