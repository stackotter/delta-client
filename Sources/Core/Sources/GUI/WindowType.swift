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

  /// The window types understood by vanilla.
  public static let types = [Id: Self](
    values: [
      inventory,
      craftingTable,
      anvil,
      furnace,
      blastFurnace,
      smoker,
      beacon,
      generic9x1,
      generic9x2,
      generic9x3,
      generic9x4,
      generic9x5,
      generic9x6,
      generic3x3,
    ],
    keyedBy: \.id
  )

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
      PlayerInventory.offHandArea,
    ]
  )

  /// A 3x3 crafting table.
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
        position: Vec2i(124, 35),
        kind: .recipeResult
      ),
      WindowArea(
        startIndex: 1,
        width: 3,
        height: 3,
        position: Vec2i(30, 17),
        kind: .fullCraftingRecipeInput
      ),
      WindowArea(
        startIndex: 10,
        width: 9,
        height: 3,
        position: Vec2i(8, 84),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 37,
        width: 9,
        height: 1,
        position: Vec2i(8, 142),
        kind: .hotbarSynced
      ),
    ]
  )

  /// An anvil.
  public static let anvil = WindowType(
    id: .vanilla(7),
    identifier: Identifier(namespace: "minecraft", name: "crafting"),
    background: .sprite(.anvil),
    slotCount: 39,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 1,
        height: 1,
        position: Vec2i(27, 47),
        kind: .firstAnvilInput
      ),
      WindowArea(
        startIndex: 1,
        width: 1,
        height: 1,
        position: Vec2i(76, 47),
        kind: .secondAnvilInput
      ),
      WindowArea(
        startIndex: 2,
        width: 1,
        height: 1,
        position: Vec2i(134, 47),
        kind: .recipeResult
      ),
      WindowArea(
        startIndex: 3,
        width: 9,
        height: 3,
        position: Vec2i(8, 84),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 30,
        width: 9,
        height: 1,
        position: Vec2i(8, 142),
        kind: .hotbarSynced
      ),
    ]
  )

  /// The areas of a heat recipe window (e.g. furnace, smoker, etc).
  public static let heatRecipeWindowAreas: [WindowArea] = [
    WindowArea(
      startIndex: 0,
      width: 1,
      height: 1,
      position: Vec2i(56, 17),
      kind: .heatRecipeInput
    ),
    WindowArea(
      startIndex: 1,
      width: 1,
      height: 1,
      position: Vec2i(56, 53),
      kind: .heatRecipeFuel
    ),
    WindowArea(
      startIndex: 2,
      width: 1,
      height: 1,
      position: Vec2i(112, 31),
      kind: .recipeResult
    ),
    WindowArea(
      startIndex: 3,
      width: 9,
      height: 3,
      position: Vec2i(8, 84),
      kind: .inventorySynced
    ),
    WindowArea(
      startIndex: 30,
      width: 9,
      height: 1,
      position: Vec2i(8, 142),
      kind: .hotbarSynced
    ),
  ]

  /// A regular furnace.
  public static let furnace = WindowType(
    id: .vanilla(13),
    identifier: Identifier(namespace: "minecraft", name: "furnace"),
    background: .sprite(.furnace),
    slotCount: 39,
    areas: heatRecipeWindowAreas
  )

  /// A blast furnace.
  public static let blastFurnace = WindowType(
    id: .vanilla(9),
    identifier: Identifier(namespace: "minecraft", name: "blast_furnace"),
    background: .sprite(.blastFurnace),
    slotCount: 39,
    areas: heatRecipeWindowAreas
  )

  /// A smoker.
  public static let smoker = WindowType(
    id: .vanilla(21),
    identifier: Identifier(namespace: "minecraft", name: "smoker"),
    background: .sprite(.smoker),
    slotCount: 39,
    areas: heatRecipeWindowAreas
  )

  /// A beacon block interface.
  public static let beacon = WindowType(
    id: .vanilla(8),
    identifier: Identifier(namespace: "minecraft", name: "beacon"),
    background: .sprite(.beacon),
    slotCount: 37,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 1,
        height: 1,
        position: Vec2i(136, 110)
      ),
      WindowArea(
        startIndex: 1,
        width: 9,
        height: 3,
        position: Vec2i(36, 137),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 28,
        width: 9,
        height: 1,
        position: Vec2i(36, 196),
        kind: .hotbarSynced
      ),
    ]
  )

  // A dispenser or dropper.
  public static let generic3x3 = WindowType(
    id: .vanilla(6),
    identifier: Identifier(namespace: "minecraft", name: "generic_3x3"),
    background: .sprite(.dispenser),
    slotCount: 45,
    areas: [
      WindowArea(
        startIndex: 0,
        width: 3,
        height: 3,
        position: Vec2i(62, 17)
      ),
      WindowArea(
        startIndex: 9,
        width: 9,
        height: 3,
        position: Vec2i(8, 84),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 36,
        width: 9,
        height: 1,
        position: Vec2i(8, 142),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 1-row container.
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
        position: Vec2i(8, 50),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 36,
        width: 9,
        height: 1,
        position: Vec2i(8, 108),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 2-row container.
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
        position: Vec2i(8, 68),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 45,
        width: 9,
        height: 1,
        position: Vec2i(8, 126),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 3-row container (e.g. a single chest).
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
        position: Vec2i(8, 86),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 54,
        width: 9,
        height: 1,
        position: Vec2i(8, 144),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 4-row container.
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
        position: Vec2i(8, 104),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 63,
        width: 9,
        height: 1,
        position: Vec2i(8, 162),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 4-row container.
  public static let generic9x5 = WindowType(
    id: .vanilla(4),
    identifier: Identifier(namespace: "minecraft", name: "generic_9x5"),
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
        position: Vec2i(8, 122),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 72,
        width: 9,
        height: 1,
        position: Vec2i(8, 180),
        kind: .hotbarSynced
      ),
    ]
  )

  /// A 6-row container (e.g. a double chest).
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
        position: Vec2i(8, 140),
        kind: .inventorySynced
      ),
      WindowArea(
        startIndex: 81,
        width: 9,
        height: 1,
        position: Vec2i(8, 198),
        kind: .hotbarSynced
      ),
    ]
  )
}
