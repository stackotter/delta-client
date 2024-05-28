/// A slice of the GUI array texture.
public enum GUITextureSlice: Int, CaseIterable {
  case bars
  case icons
  case widgets
  case inventory
  case craftingTable
  case genericContainer

  /// The path of the slice's underlying texture in a resource pack's textures directory.
  public var path: String {
    switch self {
      case .bars:
        return "bars.png"
      case .icons:
        return "icons.png"
      case .widgets:
        return "widgets.png"
      case .inventory:
        return "container/inventory.png"
      case .craftingTable:
        return "container/crafting_table.png"
      case .genericContainer:
        return "container/generic_54.png"
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
      case .inventory:
        return Identifier(name: "gui/container/inventory")
      case .craftingTable:
        return Identifier(name: "gui/container/crafting_table")
      case .genericContainer:
        return Identifier(name: "gui/container/generic_54")
    }
  }
}
