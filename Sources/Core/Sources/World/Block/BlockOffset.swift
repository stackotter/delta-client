import Foundation

extension Block {
  /// Offset types that can be applied to a block's position before rendering.
  public enum Offset: String, Codable {
    case xyz
    case xz
  }
}
