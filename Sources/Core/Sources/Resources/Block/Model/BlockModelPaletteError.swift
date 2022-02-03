import Foundation

enum BlockModelPaletteError: LocalizedError {
  /// Block model references non-existent parent.
  case noSuchParent(Identifier)
  /// Failed to flatten the block model with this identifier.
  case failedToFlatten(Identifier)
  /// No model exists with the given identifier.
  case invalidIdentifier
  /// The texture specified does not exist.
  case invalidTextureIdentifier(Identifier)
  /// The face UVs in a block model file did not have a length of 4.
  case invalidUVs
  /// A Mojang block model json file had an invalid string as a face direction.
  case invalidDirectionString(String)
  /// A texture had an invalid identifier string (likely a texture variable).
  case invalidTexture(String)
  /// An invalid direction was found in the Protobuf cache.
  case invalidDirection
  /// An invalid texture type was found in the Protobuf cache.
  case invalidTextureType
  /// A matrix was stored with an invalid number of bytes in the Protobuf cache. Expected to be 64.
  case invalidMatrixDataLength(Int)
  /// Invalid computed tint type in cached protobuf message.
  case invalidComputedTintType(Int)
  /// Invalid block tint in cached protobuf message.
  case invalidBlockTint
  /// Invalid block offset in cached protobuf message.
  case invalidBlockOffset
}
