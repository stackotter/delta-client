import Foundation

/// An item model as found in a resource pack.
struct JSONItemModel: Decodable {
  /// The parent model.
  var parent: Identifier?
  /// The display transforms to use when rendering the item in different locations.
  var display: JSONModelDisplayTransforms?
  /// The item's textures.
  var textures: [String: String]?
  /// The type of shading to apply.
  var guiLight: JSONItemModelGUILight?
  /// Replacements for this model used under certain conditions.
  var overrides: [JSONItemModelOverride]?

  func merge(withChild child: JSONItemModel) -> JSONItemModel {
    let display = display?.merge(withChild: child.display ?? JSONModelDisplayTransforms()) ?? child.display
    var textures: [String: String] = textures ?? [:]
    for (key, value) in child.textures ?? [:] {
      textures[key] = value
    }
    let guiLight = child.guiLight ?? guiLight
    let overrides = (child.overrides ?? []) + (overrides ?? [])

    return JSONItemModel(
      parent: parent,
      display: display,
      textures: textures,
      guiLight: guiLight,
      overrides: overrides
    )
  }
}
