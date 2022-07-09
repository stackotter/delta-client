import Foundation

/// The type of shading used for an item model when rendered in the gui (e.g. in the inventory).
enum JSONItemModelGUILight: String, Decodable {
  /// No shading.
  case front
  /// Shaded like a block.
  case side
}
