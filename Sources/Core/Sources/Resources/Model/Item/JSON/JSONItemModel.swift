import Foundation

/// An item model as found in a resource pack.
struct JSONItemModel: Decodable {
  /// The parent model.
  var parent: Identifier?
  /// The display transforms to use when rendering the item in different locations.
  var display: [String: JSONModelDisplayTransforms]?
  /// The item's textures.
  var textures: [String: String]?
  /// The type of shading to apply.
  var guiLight: JSONItemModelGUILight?
  /// Replacements for this model used under certain conditions.
  var overrides: [JSONItemModelOverride]?
}
