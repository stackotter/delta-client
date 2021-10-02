import Foundation

/// Holds the information about blocks that isn't affected by resource packs.
public struct BlockRegistry {
  /// Blocks indexed by identifier.
  public var blocks: [Int: Block] = [:]
  /// Block states indexed by block state id.
  public var states: [Int: BlockState] = [:]
  /// Map from block identifier to block id.
  public var identifierToBlockId: [Identifier: Int] = [:]
  
  /// Maps block state id to an array containing an array for each variant. The array for each variant contains the models to render.
  public var renderDescriptors: [Int: [[BlockModelRenderDescriptor]]] = [:]
  
  /// Contains the block state ids of all blocks that cull the faces of blocks with the same id that aren't opaque (e.g. glass blocks).
  public var selfCullingBlockStates: Set<Int> = []
  
  // MARK: Init
  
  /// Creates an empty block registry. It's best to use the other initializer unless you really know what you're doing.
  public init() {}
  
  /// Creates a populated block registry.
  /// - Parameters:
  ///   - identifierToBlockId: Maps block identifier to block id.
  ///   - blocks: Maps block id to block.
  ///   - states: Maps block state id to block state.
  ///   - renderDescriptors: Descriptions of what to render for each block.
  ///   - selfCullingBlockClassesOverrides: Block classes of blocks that cull blocks of the same state id. If `nil`, the vanilla overrides are used.
  public init(
    identifierToBlockId: [Identifier : Int],
    blocks: [Int : Block],
    states: [Int : BlockState],
    renderDescriptors: [Int : [[BlockModelRenderDescriptor]]],
    selfCullingBlockClasses: Set<String>? = nil
  ) {
    self.identifierToBlockId = identifierToBlockId
    self.blocks = blocks
    self.states = states
    self.renderDescriptors = renderDescriptors
    
    // I'm really struggling to find a good name for this value and everything else around this stuff. Its basically just a way to hardcode certain blocks that cull the faces of their own kind (e.g. glass blocks).
    let selfCullingBlockClasses = selfCullingBlockClasses ?? ["StainedGlassBlock", "GlassBlock", "LeavesBlock"]
    for (_, block) in blocks {
      if selfCullingBlockClasses.contains(block.className) {
        selfCullingBlockStates.formUnion(Set(block.states))
      }
    }
  }
  
  // MARK: Access
  
  /// Get the block id for the specified block.
  /// - Parameter identifier: A block identifier.
  /// - Returns: A block id. `nil` if block doesn't exist.
  public func blockId(for identifier: Identifier) -> Int? {
    return identifierToBlockId[identifier]
  }
  
  /// Get information about the specified block.
  /// - Parameter blockId: A block id.
  /// - Returns: Information about a block. `nil` if block doesn't exist.
  public func block(withId blockId: Int) -> Block? {
    return blocks[blockId]
  }
  
  /// Get information about the block containing the specified block state.
  /// - Parameter stateId: A block state id.
  /// - Returns: Information about a block. `nil` if block state is invalid or parent block doesn't exist.
  public func block(forStateWithId stateId: Int) -> Block? {
    if let blockId = states[stateId]?.blockId {
      return blocks[blockId]
    } else {
      return nil
    }
  }
  
  /// Get information about a block state.
  /// - Parameter stateId: A block state id.
  /// - Returns: Information about a block state. `nil` if block state doesn't exist.
  public func blockState(withId stateId: Int) -> BlockState? {
    return states[stateId]
  }
}

extension BlockRegistry: PixlyzerRegistry {
  public static func load(from pixlyzerBlockPaletteFile: URL) throws -> BlockRegistry {
    // Read global block palette from the pixlyzer block palette
    let data = try Data(contentsOf: pixlyzerBlockPaletteFile)
    let pixlyzerPalette = try JSONDecoder().decode([String:PixlyzerBlock].self, from: data)
    
    // Convert the pixlyzer data to a slightly nicer format
    var identifierToBlockId: [Identifier: Int] = [:]
    var blocks: [Int: Block] = [:]
    var blockStates: [Int: BlockState] = [:]
    var renderDescriptors: [Int: [[BlockModelRenderDescriptor]]] = [:]
    for (identifierString, pixlyzerBlock) in pixlyzerPalette {
      let identifier = try Identifier(identifierString)
      let block = Block(from: pixlyzerBlock, identifier: identifier)
      identifierToBlockId[identifier] = block.id
      blocks[block.id] = block
      
      for (stateId, pixlyzerState) in pixlyzerBlock.states {
        let state = BlockState(from: pixlyzerState, withId: stateId, onBlockWithId: block.id)
        blockStates[stateId] = state
      }
      
      // Get the block models for this block's states and variants
      let pixlyzerBlockModels = pixlyzerBlock.blockModelDescriptors
      for (stateId, pixlyzerModelDescriptors) in pixlyzerBlockModels {
        renderDescriptors[stateId] = pixlyzerModelDescriptors.map { multipart in
          multipart.map { descriptor in
            BlockModelRenderDescriptor(from: descriptor)
          }
        }
      }
    }
    
    return BlockRegistry(
      identifierToBlockId: identifierToBlockId,
      blocks: blocks,
      states: blockStates,
      renderDescriptors: renderDescriptors)
  }
  
  static func getDownloadURL(for version: String) -> URL {
    return URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/blocks.min.json")!
  }
}
