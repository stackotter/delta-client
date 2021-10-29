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
  /// The type of texture that the block has.
  ///
  /// If the block has any translucent faces, the type is translucent. If the block has no translucent faces but
  /// at least one transparent face, the type is transparent. If all of the faces are opaque, the type is opaque.
  public var textureType: TextureType
}
