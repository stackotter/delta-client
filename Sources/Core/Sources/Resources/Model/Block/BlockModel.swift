import Foundation

/// A descriptor for a multipart block model.
public struct BlockModel: Equatable {
  /// The parts that make up this block model
  public var parts: [BlockModelPart]
  /// The set of all the sides this model has full faces on.
  public var cullingFaces: DirectionSet
  /// The set of all sides this model has faces that can be culled.
  public var cullableFaces: DirectionSet
  /// The set of all sides this model has faces that can never be culled.
  public var nonCullableFaces: DirectionSet
  /// The type of texture that the block has.
  ///
  /// If the block has any translucent faces, the type is translucent. If the block has no
  /// translucent faces but at least one partially transparent face, the type is transparent. If all
  /// of the faces are fully opaque, the type is opaque.
  public var textureType: TextureType

  public init(
    parts: [BlockModelPart],
    cullingFaces: DirectionSet,
    cullableFaces: DirectionSet,
    nonCullableFaces: DirectionSet,
    textureType: TextureType
  ) {
    self.parts = parts
    self.cullingFaces = cullingFaces
    self.cullableFaces = cullableFaces
    self.nonCullableFaces = nonCullableFaces
    self.textureType = textureType
  }
}
