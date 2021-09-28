import Foundation

/// The possible texture types.
public enum TextureType {
  /// The texture only contains opaque pixels.
  case opaque
  /// The texture contains some fully transparent pixels but no translucent pictures.
  case transparent
  /// The texture contains translucent pixels (semi-transparent).
  case translucent
}
