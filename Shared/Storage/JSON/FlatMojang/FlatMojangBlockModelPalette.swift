//
//  FlatMojangBlockModelPalette.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// Flattened mojang block models are in a format that means they contain all the information they require (no complex parent lookups).
/// This format just simplifies processing of the mojang block models into DeltaClient block models and serves as an temporary intermediate format.
public struct FlatMojangBlockModelPalette {
  /// Map from identifier to index in `blockModels`.
  public var identifierToIndex: [Identifier: Int] = [:]
  /// Array of flattened mojang block models indexed by `identifierToIndex`.
  public var blockModels: [FlatMojangBlockModel] = []
  /// Array of transforms to use when displaying blocks. Indexed by `displayTransformsIndex` on `FlatMojangBlockModel`s.
  public var displayTransforms: [BlockModelDisplayTransforms] = []
  
  /// Creates a new block model palette by flattening the given mojang block models.
  public init(from mojangBlockModelPalette: [Identifier: MojangBlockModel]) throws {
    for (identifier, blockModel) in mojangBlockModelPalette {
      // If the block model hasn't already been flattened, flatten it.
      // It will already have been flattened if it is the parent of an already flattened block model.
      if !identifierToIndex.keys.contains(identifier) {
        do {
          let flattened = try flatten(blockModel, with: mojangBlockModelPalette, and: identifier)
          append(flattened, as: identifier)
        } catch {
          log.error("Failed to flatten mojang block model: \(error)")
          throw BlockPaletteError.failedToFlatten(identifier)
        }
      }
    }
  }
  
  /// Returns the flattened block model from the palette for the given identifier if present.
  public func blockModel(for identifier: Identifier) -> FlatMojangBlockModel? {
    if let index = identifierToIndex[identifier] {
      return blockModels[index]
    }
    return nil
  }
  
  /// Flattens a mojang formatted block model. Also flattens any parents of the model and adds them to the palette.
  private mutating func flatten(
    _ mojangBlockModel: MojangBlockModel,
    with mojangBlockPalette: [Identifier: MojangBlockModel],
    and identifier: Identifier
  ) throws -> FlatMojangBlockModel {
    // Flatten the parent first if this model has a parent.
    var parent: FlatMojangBlockModel? = nil
    if let parentIdentifier = mojangBlockModel.parent {
      guard let parentMojangBlockModel = mojangBlockPalette[parentIdentifier] else {
        throw BlockPaletteError.noSuchParent(parentIdentifier)
      }
      
      // Use a cached version of the parent if it has already been processed, otherwise flatten it normally
      if let flattenedParent = blockModel(for: parentIdentifier) {
        parent = flattenedParent
      } else {
        let flattened = try flatten(parentMojangBlockModel, with: mojangBlockPalette, and: parentIdentifier)
        append(flattened, as: parentIdentifier)
        parent = flattened
      }
    }
    
    // Flatten the block model elements if present, otherwise use the parent's elements or [] if neither are present
    let textureVariables = mojangBlockModel.textures ?? [:]
    var flattenedElements = parent?.elements ?? []
    if let mojangElements = mojangBlockModel.elements {
      flattenedElements = try mojangElements.map { mojangElement in
        try FlatMojangBlockModelElement(from: mojangElement, with: textureVariables)
      }
    }
    
    // Flatten the display transforms
    var displayTransformsIndex: Int? = nil
    if let mojangDisplayTransforms = mojangBlockModel.display {
      let flattenedDisplayTransforms = try BlockModelDisplayTransforms(from: mojangDisplayTransforms)
      displayTransformsIndex = displayTransforms.count
      displayTransforms.append(flattenedDisplayTransforms)
    }
    
    let ambientOcclusion = mojangBlockModel.ambientOcclusion ?? (parent?.ambientOcclusion ?? true)
    return FlatMojangBlockModel(
      ambientOcclusion: ambientOcclusion,
      displayTransformsIndex: displayTransformsIndex,
      elements: flattenedElements)
  }
  
  /// Appends the given flattened block model to the palette, and it's it to the palette lookup under the given identifier.
  private mutating func append(_ flattened: FlatMojangBlockModel, as identifier: Identifier) {
    let index = blockModels.count
    identifierToIndex[identifier] = index
    blockModels[index] = flattened
  }
}
