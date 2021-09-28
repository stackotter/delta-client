import Foundation

public struct BlockModel {
  /// The parts that make up this block model
  public var parts: [BlockModelPart]
  /// The set of all the sides this model has full faces on.
  public var cullingFaces: Set<Direction>
  /// The set of all sides this model has faces that can be culled.
  public var cullableFaces: Set<Direction>
  /// The set of all sides this model has faces that can never be culled.
  public var nonCullableFaces: Set<Direction>
}
