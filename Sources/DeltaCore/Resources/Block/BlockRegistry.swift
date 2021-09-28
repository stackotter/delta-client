//
//  BlockRegistry.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 17/7/21.
//

import Foundation

/// A registry containing all the static information about blocks (not affected by resource packs).
public class BlockRegistry {
  public var identifierToBlockId: [Identifier: Int]
  /// Blocks indexed by identifier.
  public var blocks: [Int: Block]
  /// Block states indexed by block state id.
  public var states: [Int: BlockState]
  
  /// Maps block state id to an array containing an array for each variant. The array for each variant contains the models to render.
  public var renderDescriptors: [Int: [[BlockModelRenderDescriptor]]]
  
  // MARK: Init
  
  public init() {
    self.identifierToBlockId = [:]
    self.blocks = [:]
    self.states = [:]
    self.renderDescriptors = [:]
  }
  
  public init(
    identifierToBlockId: [Identifier : Int],
    blocks: [Int : Block],
    states: [Int : BlockState],
    renderDescriptors: [Int : [[BlockModelRenderDescriptor]]]
  ) {
    self.identifierToBlockId = identifierToBlockId
    self.blocks = blocks
    self.states = states
    self.renderDescriptors = renderDescriptors
  }
  
  // MARK: Loading
  
  public static func load(fromPixlyzerDataDirectory pixlyzerDirectory: URL) throws -> BlockRegistry {
    // Read global block palette from the pixlyzer block palette
    let pixlyzerBlockPaletteFile = pixlyzerDirectory.appendingPathComponent("blocks.min.json")
    let data = try Data(contentsOf: pixlyzerBlockPaletteFile)
    let pixlyzerPalette = try JSONDecoder().decode(PixlyzerBlockPalette.self, from: data)
    
    // Convert the pixlyzer data to a slightly nicer format
    var identifierToBlockId: [Identifier: Int] = [:]
    var blocks: [Int: Block] = [:]
    var blockStates: [Int: BlockState] = [:]
    var renderDescriptors: [Int: [[BlockModelRenderDescriptor]]] = [:]
    for (identifier, pixlyzerBlock) in pixlyzerPalette.palette {
      let block = Block(from: pixlyzerBlock)
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
  
  // MARK: Access
  
  public func getBlock(withId blockId: Int) -> Block? {
    return blocks[blockId]
  }
  
  public func getBlockForState(withId stateId: Int) -> Block? {
    if let blockId = states[stateId]?.blockId {
      return blocks[blockId]
    } else {
      return nil
    }
  }
  
  public func getBlockState(withId stateId: Int) -> BlockState? {
    return states[stateId]
  }
}
