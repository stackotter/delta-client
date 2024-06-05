/// A slice of the GUI array texture.
public enum GUITextureSlice: Int, CaseIterable {
  case bars
  case icons
  case widgets
  case inventory
  case craftingTable
  case genericContainer
  case dispenser // also covers dropper
  case anvil
  case beacon
  case blastFurnace
  case brewingStand
  case enchantingTable
  case furnace
  case grindstone
  case hopper
  case loom
  case merchant // Villagers & wandering traders
  case shulkerBox
  case smithingTable
  case smoker
  case cartographyTable
  case stonecutter

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
      case .dispenser:
        return "container/dispenser.png"
      case .anvil:
        return "container/anvil.png"
      case .beacon:
        return "container/beacon.png"
      case .blastFurnace:
        return "container/blast_furnace.png"
      case .brewingStand:
        return "container/brewing_stand.png"
      case .enchantingTable:
        return "container/enchanting_table.png"
      case .furnace:
        return "container/furnace.png"
      case .grindstone:
        return "container/grindstone.png"
      case .hopper:
        return "container/hopper.png"
      case .loom:
        return "container/loom.png"
      case .merchant:
        return "container/villager2.png"
      case .shulkerBox:
        return "container/shulker_box.png"
      case .smithingTable:
        return "container/smithing.png"
      case .smoker:
        return "container/smoker.png"
      case .cartographyTable:
        return "container/cartography_table.png"
      case .stonecutter:
        return "container/stonecutter.png"
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
      case .dispenser:
        return Identifier(name: "gui/container/dispenser")
      case .anvil:
        return Identifier(name: "gui/container/anvil")
      case .beacon:
        return Identifier(name: "gui/container/beacon")
      case .blastFurnace:
        return Identifier(name: "gui/container/blast_furnace")
      case .brewingStand:
        return Identifier(name: "gui/container/brewing_stand")
      case .enchantingTable:
        return Identifier(name: "gui/container/enchanting_table")
      case .furnace:
        return Identifier(name: "gui/container/furnace")
      case .grindstone:
        return Identifier(name: "gui/container/grindstone")
      case .hopper:
        return Identifier(name: "gui/container/hopper")
      case .loom:
        return Identifier(name: "gui/container/loom")
      case .merchant:
        return Identifier(name: "gui/container/villager2")
      case .shulkerBox:
        return Identifier(name: "gui/container/shulker_box")
      case .smithingTable:
        return Identifier(name: "gui/container/smithing")
      case .smoker:
        return Identifier(name: "gui/container/smoker")
      case .cartographyTable:
        return Identifier(name: "gui/container/cartography_table")
      case .stonecutter:
        return Identifier(name: "gui/container/stonecutter")
    }
  }
}
