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

 // Generic window types
public static let generic9x1 = WindowType(
    id: .vanilla(0),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x1"),
    background: GUIElement.list(spacing: 0) {
            GUIElement.sprite(.generic9x1)
            GUIElement.sprite(.singleChestBottomHalf)
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
            GUIElement.sprite(.singleChestBottomHalf)
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

public static let generic9x4 = WindowType(
    id: .vanilla(3),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x4"),
    background: GUIElement.list(spacing: 0) {
        GUIElement.sprite(.generic9x4)
        GUIElement.sprite(.singleChestBottomHalf) // Use the inventory section of the bottom half of the chest, wouldn't a more generic name for it be better?
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
            GUIElement.sprite(.singleChestBottomHalf) // Same reasoning as 9x4
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

  /// The window types understood by vanilla.
  public static let types = [Id: Self](
    values: [
      inventory,
      craftingTable,
      chest,
      doubleChest,
      generic9x1,
      generic9x2,
      generic9x4,
      generic9x5
    ],
    keyedBy: \.id
  )
}
