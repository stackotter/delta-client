/// A type of GUI window (e.g. inventory, crafting table, chest, etc). Defines the layout
/// and which slots go where.
public struct WindowType {
  public var id: Id
  public var identifier: Identifier
  public var background: GUIElement
  public var slotCount: Int
  public var areas: [WindowArea]

  public enum Id: Hashable, Equatable {
    case inventory
    case vanilla(Int)
  }

  /// The player's inventory.
  public static let inventory = WindowType(
    id: .inventory,
    identifier: Identifier(namespace: "minecraft", name: "inventory"),
    background: .sprite(.inventory),
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

  public static let craftingTable = WindowType(
    id: .vanilla(11),
    identifier: Identifier(namespace: "minecraft", name: "crafting"),
    background: .sprite(.craftingTable),
    slotCount: 46,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 1,
        height: 1,
        position: Vec2i(124, 35)
      ),
      WindowArea(
        startIndex: 1,
        width: 3,
        height: 3,
        position: Vec2i(30, 17)
      ),
      WindowArea(
        startIndex: 10,
        width: 9,
        height: 3,
        position: Vec2i(8, 84)
      ),
      WindowArea(
        startIndex: 37,
        width: 9,
        height: 1,
        position: Vec2i(8, 142)
      ),
    ]
  )

  public static let chest = WindowType(
    id: .vanilla(2),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x3"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.singleChestTopHalf)
      GUIElement.sprite(.singleChestBottomHalf)
    },
    slotCount: 63,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 3,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 27,
        width: 9,
        height: 3,
        position: Vec2i(8, 86)
      ),
      WindowArea(
        startIndex: 54,
        width: 9,
        height: 1,
        position: Vec2i(8, 144)
      ),
    ]
  )

  public static let doubleChest = WindowType(
    id: .vanilla(5),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x6"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.doubleChest)
    },
    slotCount: 90,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 6,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 54,
        width: 9,
        height: 3,
        position: Vec2i(8, 140)
      ),
      WindowArea(
        startIndex: 81,
        width: 9,
        height: 1,
        position: Vec2i(8, 198)
      ),
    ]
  )

  /// The window types understood by vanilla.
  public static let types = [Id: Self](
    values: [
      inventory,
      craftingTable,
      chest,
      doubleChest
    ],
    keyedBy: \.id
  )
}
