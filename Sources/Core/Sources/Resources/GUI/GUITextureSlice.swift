/// A slice of the GUI array texture.
public enum GUITextureSlice: Int, CaseIterable {
  case bars
  case icons
  case widgets

  /// The path of the slice's underlying texture in a resource pack's textures directory.
  public var path: String {
    switch self {
      case .bars:
        return "bars.png"
      case .icons:
        return "icons.png"
      case .widgets:
        return "widgets.png"
    }
  }

  /// The identifier of the slice's underlying texture.
  public var identifier: Identifier {
    switch self {
      case .bars:
        return Identifier(name: "gui/bars")
      case .icons:
        return Identifier(name: "gui/icons")
      case .widgets:
        return Identifier(name: "gui/widgets")
    }
  }
}
