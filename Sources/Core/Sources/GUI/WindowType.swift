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

  public static let anvil = WindowType(
    id: .vanilla(7),
    identifier: Identifier(namespace: "minecraft", name: "crafting"),
    background: .sprite(.anvil),
    slotCount: 39,
    areas:[
      WindowArea(
        startIndex: 0,
        width: 1,
        height: 1,
        position: Vec2i(27, 47)
      ),
      WindowArea(
        startIndex: 1,
        width: 1,
        height: 1,
        position: Vec2i(76, 47)
      ),
      WindowArea(
        startIndex: 2,
        width: 1,
        height: 1,
        position: Vec2i(134, 47)
      ),
      WindowArea(
        startIndex: 3,
        width: 9,
        height: 3,
        position: Vec2i(8, 84)
      ),
      WindowArea(
        startIndex: 30,
        width: 9,
        height: 1,
        position: Vec2i(8, 142)
      )
    ]
  )

  // Generic window types
  public static let generic9x1 = WindowType(
    id: .vanilla(0),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x1"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x1)
      GUIElement.sprite(.genericInventory)
    },
    slotCount: 45,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 1,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 9,
        width: 9,
        height: 3,
        position: Vec2i(8, 50)
      ),
      WindowArea(
        startIndex: 36,
        width: 9,
        height: 1,
        position: Vec2i(8, 108)
      )
    ]
  )

  public static let generic9x2 = WindowType(
    id: .vanilla(1),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x2"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x2)
      GUIElement.sprite(.genericInventory)
    },
    slotCount: 54,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 2,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 18,
        width: 9,
        height: 3,
        position: Vec2i(8, 68)
      ),
      WindowArea(
        startIndex: 45,
        width: 9,
        height: 1,
        position: Vec2i(8, 126)
      )
    ]
  )

  public static let generic9x3 = WindowType(
    id: .vanilla(2),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x3"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x3)
      GUIElement.sprite(.genericInventory)
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

  public static let generic9x4 = WindowType(
    id: .vanilla(3),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x4"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x4)
      GUIElement.sprite(.genericInventory)
    },
    slotCount: 72,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 4,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 36,
        width: 9,
        height: 3,
        position: Vec2i(8, 104)
      ),
      WindowArea(
        startIndex: 63,
        width: 9,
        height: 1,
        position: Vec2i(8, 162)
      )
    ]
  )

  public static let generic9x5 = WindowType(
    id: .vanilla(4),
    identifier: Identifier(namespace: "minecraft", name:"generic_9x5"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x5)
      GUIElement.sprite(.genericInventory)
    },
    slotCount: 81,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 9,
        height: 5,
        position: Vec2i(8, 18)
      ),
      WindowArea(
        startIndex: 45,
        width: 9,
        height: 3,
        position: Vec2i(8, 122)
      ),
      WindowArea(
        startIndex: 72,
        width: 9,
        height: 1,
        position: Vec2i(8, 180)
      )
    ]
  )

  public static let generic9x6 = WindowType(
    id: .vanilla(5),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x6"),
    background: GUIElement.list(spacing: 0) {
      GUIElement.sprite(.generic9x6)
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
      anvil,
      generic9x1,
      generic9x2,
      generic9x3,
      generic9x4,
      generic9x5,
      generic9x6,
    ],
    keyedBy: \.id
  )
}
