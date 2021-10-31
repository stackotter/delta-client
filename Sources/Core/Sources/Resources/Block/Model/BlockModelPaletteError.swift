import Foundation

enum BlockModelPaletteError: LocalizedError {
  /// Block model references non-existent parent.
  case noSuchParent(Identifier)
  /// Failed to flatten the block model with this identifier.
  case failedToFlatten(Identifier)
  /// Incorrect number of elements in array representing 3d vector.
  case invalidVector
  /// No model exists with the given identifier.
  case invalidIdentifier
  /// The texture specified does not exist.
  case invalidTextureIdentifier(Identifier)
  /// The texture rotation is not a multiple of 90 in range 0 to 270 inclusive.
  case invalidTextureRotation(degrees: Int)
  /// The face UVs in a block model file did not have a length of 4.
  case invalidUVs
  /// The given block state id is too high or low.
  case invalidBlockStateId(Int)
  /// A Mojang block model json file had an invalid string as a face direction.
  case invalidDirectionString(String)
  /// A texture had an invalid identifier string (likely a texture variable).
  case invalidTexture(String)
}
