import Foundation
import simd

/// This format just simplifies processing of the mojang block models into DeltaClient block models and serves as an temporary intermediate format.
/// It flattens the complex dependency tree of block models so that all relevant information is in each block model. This prevents repetitive parent lookups.
public struct IntermediateBlockModelPalette {
  /// Map from identifier to index in `blockModels`.
  public var identifierToIndex: [Identifier: Int] = [:]
  /// Array of flattened mojang block models indexed by `identifierToIndex`.
  public var blockModels: [IntermediateBlockModel] = []
  /// Array of transforms to use when displaying blocks. Indexed by `displayTransformsIndex` on `FlatJSONBlockModel`s.
  public var displayTransforms: [BlockModelDisplayTransforms] = []
  
  /// Creates a new block model palette by flattening the given mojang block models.
  public init(from jsonBlockModelPalette: [Identifier: JSONBlockModel]) throws {
    for (identifier, blockModel) in jsonBlockModelPalette {
      // If the block model hasn't already been flattened, flatten it.
      // It will already have been flattened if it is the parent of an already flattened block model.
      if !identifierToIndex.keys.contains(identifier) {
        do {
          let flattened = try flatten(blockModel, with: jsonBlockModelPalette)
          append(flattened, as: identifier)
        } catch {
          log.error("Failed to flatten mojang block model: \(error)")
          throw BlockModelPaletteError.failedToFlatten(identifier)
        }
      }
    }
  }
  
  /// Returns the flattened block model from the palette for the given identifier if present.
  public func blockModel(for identifier: Identifier) -> IntermediateBlockModel? {
    if let index = identifierToIndex[identifier] {
      return blockModels[index]
    }
    return nil
  }
  
  /// Flattens a mojang formatted block model. Also flattens any parents of the model and adds them to the palette.
  private mutating func flatten(
    _ jsonBlockModel: JSONBlockModel,
    with jsonBlockPalette: [Identifier: JSONBlockModel]
  ) throws -> IntermediateBlockModel {
    // Flatten the parent first if this model has a parent.
    var parent: IntermediateBlockModel?
    if let parentIdentifier = jsonBlockModel.parent {
      guard let parentJSONBlockModel = jsonBlockPalette[parentIdentifier] else {
        throw BlockModelPaletteError.noSuchParent(parentIdentifier)
      }
      
      // Use a cached version of the parent if it has already been processed, otherwise flatten it normally
      if let flattenedParent = blockModel(for: parentIdentifier) {
        parent = flattenedParent
      } else {
        let flattened = try flatten(parentJSONBlockModel, with: jsonBlockPalette)
        append(flattened, as: parentIdentifier)
        parent = flattened
      }
    }
    
    // Flatten the block model elements if present, otherwise use the parent's elements or [] if neither are present
    let textureVariables = jsonBlockModel.textures ?? [:]
    var flattenedElements: [IntermediateBlockModelElement] = []
    if let jsonElements = jsonBlockModel.elements {
      flattenedElements = try jsonElements.map { jsonElement in
        try IntermediateBlockModelElement(from: jsonElement, with: textureVariables)
      }
    } else {
      // If this model doesn't have any elements use its parents and update them with this model's texture variables
      flattenedElements = parent?.elements ?? []
      if !textureVariables.isEmpty {
        for (index, var element) in flattenedElements.enumerated() {
          element.updateTextures(with: textureVariables)
          flattenedElements[index] = element
        }
      }
    }
    
    // Flatten the display transforms
    var displayTransformsIndex: Int?
    if let jsonDisplayTransforms = jsonBlockModel.display {
      let flattenedDisplayTransforms = try BlockModelDisplayTransforms(from: jsonDisplayTransforms)
      displayTransformsIndex = displayTransforms.count
      displayTransforms.append(flattenedDisplayTransforms)
    }
    
    let ambientOcclusion = jsonBlockModel.ambientOcclusion ?? (parent?.ambientOcclusion ?? true)
    return IntermediateBlockModel(
      ambientOcclusion: ambientOcclusion,
      displayTransformsIndex: displayTransformsIndex,
      elements: flattenedElements)
  }
  
  /// Appends the given flattened block model to the palette, and it's it to the palette lookup under the given identifier.
  private mutating func append(_ flattened: IntermediateBlockModel, as identifier: Identifier) {
    let index = blockModels.count
    identifierToIndex[identifier] = index
    blockModels.append(flattened)
  }
}
