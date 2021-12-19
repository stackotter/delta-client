import Foundation

/// This is what Mojang calls a block model, I use the word block model to refer the models for each block state which can be made of multiple parts.
public struct BlockModelPart {
  /// Whether to use ambient occlusion or not.
  public var ambientOcclusion: Bool
  /// Index of the transforms to use when displaying this block.
  public var displayTransformsIndex: Int?
  /// The elements that make up this block model.
  public var elements: [BlockModelElement] = []
  
  public init(ambientOcclusion: Bool, displayTransformsIndex: Int? = nil, elements: [BlockModelElement]) {
    self.ambientOcclusion = ambientOcclusion
    self.displayTransformsIndex = displayTransformsIndex
    self.elements = elements
  }
}
