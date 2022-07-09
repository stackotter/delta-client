import Foundation

/// Flattened mojang block model format.
struct IntermediateBlockModel {
  /// Whether to use ambient occlusion or not.
  var ambientOcclusion: Bool
  /// Index of the transforms to use when displaying this block.
  var displayTransformsIndex: Int?
  /// The elements that make up this block model.
  var elements: [IntermediateBlockModelElement]
}
