import Foundation

/// Holds the information about blocks that isn't affected by resource packs.
public struct BlockRegistry: Codable {
  /// Blocks indexed by block id.
  public var blocks: [Block] = []
  /// Maps block id to an array containing an array for each variant. The array for each variant contains the models to render.
  public var renderDescriptors: [[[BlockModelRenderDescriptor]]] = []
  
  /// Contains the block ids of all blocks that cull the faces of blocks with the same id that aren't opaque (e.g. glass blocks).
  public var selfCullingBlocks: Set<Int> = []
  /// Contains the block ids of all blocks that are air (regular air, cave air and void air).
  public var airBlocks: Set<Int> = []
  
  // MARK: Init
  
  /// Creates an empty block registry. It's best to use the other initializer unless you really know what you're doing.
  public init() {}
  
  /// Creates a populated block registry.
  /// - Parameters:
  ///   - blocks: The array of all blocks, indexed by block id.
  ///   - renderDescriptors: Descriptions of what to render for each block, indexed by block id.
  ///   - selfCullingBlockClasses: Block classes of blocks that cull blocks of the same id. If `nil`, the vanilla overrides are used.
  public init(
    blocks: [Block],
    renderDescriptors: [[[BlockModelRenderDescriptor]]],
    selfCullingBlockClasses: Set<String>? = nil
  ) {
    self.blocks = blocks
    self.renderDescriptors = renderDescriptors
    
    // I'm really struggling to find a good name for this value and everything else around this stuff. Its basically just a way to hardcode certain blocks that cull the faces of their own kind (e.g. glass blocks).
    // Fluid blocks are handled separately by the fluid renderer
    let selfCullingBlockClasses = selfCullingBlockClasses ?? ["StainedGlassBlock", "GlassBlock", "LeavesBlock"]
    for block in blocks {
      if selfCullingBlockClasses.contains(block.className) {
        selfCullingBlocks.insert(block.id)
      }
      if block.className == "AirBlock" {
        airBlocks.insert(block.id)
      }
    }
  }
  
  // MARK: Access
  
  /// Get information about the specified block.
  /// - Parameter blockId: A block id.
  /// - Returns: Information about a block. `nil` if block doesn't exist.
  public func block(withId blockId: Int) -> Block? {
    return blocks[blockId]
  }
  
  /// Get whether a block is air.
  /// - Parameter id: Id of the block of interest.
  /// - Returns: Whether the block is air.
  public func isAir(_ id: Int) -> Bool {
    return airBlocks.contains(id)
  }
}
