/// A type of GUI window (e.g. inventory, crafting table, chest, etc). Defines the layout
/// and which slots go where.
public struct WindowType {
  public var id: Id
  public var identifier: Identifier
  public var texture: GUISprite
  public var slotCount: Int
  public var areas: [WindowArea]

  public enum Id: Hashable, Equatable {
    /// Vanilla minecraft doesn't have the inventory window type in its registry
    /// cause it gets special treatment, so we just give it its own category of id.
    case inventory
    case vanilla(Int)
  }

  /// The player's inventory.
  public static let inventory = WindowType(
    id: .inventory,
    identifier: Identifier(namespace: "minecraft", name: "inventory"),
    texture: .inventory,
    slotCount: 46,
    areas: [
      PlayerInventory.mainArea,
      PlayerInventory.hotbarArea,
      PlayerInventory.craftingInputArea,
      PlayerInventory.craftingResultArea,
      PlayerInventory.armorArea,
      PlayerInventory.offHandArea
    ]
  )

  /// The window types understood by vanilla.
  public static let types = [Id: Self](
    values: [
      inventory,
    ],
    keyedBy: \.id
  )
}
