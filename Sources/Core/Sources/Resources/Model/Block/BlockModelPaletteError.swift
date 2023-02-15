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
  case invalidComputedTintTypeRawValue(ProtobufBlockComputedTintType.RawValue)
  /// Invalid block tint in cached protobuf message.
  case invalidBlockTint
  /// Invalid block offset in cached protobuf message.
  case invalidBlockOffset

  var errorDescription: String? {
    switch self {
      case .noSuchParent(let identifier):
        return "Block model references non-existent parent with identifier: `\(identifier.description)`."
      case .failedToFlatten(let identifier):
        return "Failed to flatten the block model with identifier: `\(identifier.description)`"
      case .invalidIdentifier:
        return "No model exists with the given identifier."
      case .invalidTextureIdentifier(let identifier):
        return "The texture with identifier: `\(identifier.description)` does not exist."
      case .invalidUVs:
        return "The face UVs in a block model file did not have a length of 4."
      case .invalidDirectionString(let string):
        return """
        A Mojang block model json file had an invalid string as a face direction.
        String: \(string)
        """
      case .invalidTexture(let string):
        return """
        A texture had an invalid identifier string (likely a texture variable):
        Identifier string: \(string)
        """
      case .invalidDirection:
        return "An invalid direction was found in the Protobuf cache."
      case .invalidTextureType:
        return "An invalid texture type was found in the Protobuf cache."
      case .invalidMatrixDataLength(let length):
        return "A matrix was stored with an invalid number of bytes in the Protobuf cache. Expected to be 64. Got \(length) instead"
      case .invalidComputedTintTypeRawValue(let rawValue):
        return """
        Invalid computed tint type in cached protobuf message.
        Raw value: \(rawValue)
        """
      case .invalidBlockTint:
        return "Invalid block tint in cached protobuf message."
      case .invalidBlockOffset:
        return "Invalid block offset in cached protobuf message."
    }
  }
}
