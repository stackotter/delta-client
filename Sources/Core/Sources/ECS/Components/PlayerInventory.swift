import FirebladeECS

/// A component storing the player's inventory.
public class PlayerInventory: Component {
  /// The number of slots in a player inventory (including armor and off hand).
  public static let slotCount = 46
  /// The player's inventory's window id.
  public static let windowId = 0

  /// The index of the crafting result slot.
  public static let craftingResultIndex = Area.craftingResult.startIndex
  /// The index of the player's off-hand slot.
  public static let offHandIndex = Area.offHand.startIndex

  /// The inventory's contents.
  public var slots: [Slot]
  /// The player's currently selected hotbar slot.
  public var selectedHotbarSlot: Int

  /// The action id to use for the next action performed on the inventory (used when sending
  /// ``ClickWindowPacket``).
  var nextActionId = 0

  public struct Area {
    public var startIndex: Int
    public var width: Int
    public var height: Int

    public static let main = Area(
      startIndex: 9,
      width: 9,
      height: 3
    )

    public static let hotbar = Area(
      startIndex: 36,
      width: 9,
      height: 1
    )

    public static let craftingInput = Area(
      startIndex: 1,
      width: 2,
      height: 2
    )

    public static let craftingResult = Area(
      startIndex: 0,
      width: 1,
      height: 1
    )

    public static let armor = Area(
      startIndex: 5,
      width: 1,
      height: 4
    )

    public static let offHand = Area(
      startIndex: 45,
      width: 1,
      height: 1
    )
  }

  /// The inventory's hotbar.
  public var hotbar: [Slot] {
    return slots(for: .hotbar)[0]
  }

  /// The result slot of the inventory's crafting area.
  public var craftingResult: Slot {
    return slots[Self.craftingResultIndex]
  }

  /// The armor slots.
  public var armorSlots: [Slot] {
    return slots(for: .armor).map { row in
      row[0]
    }
  }

  /// The off-hand slot.
  public var offHand: Slot {
    return slots[Self.offHandIndex]
  }

  /// Creates the player's inventory state.
  /// - Parameter selectedHotbarSlot: Defaults to 0 (the first slot from the left in the main hotbar).
  /// - Precondition: The length of `slots` must match ``PlayerInventory/slotCount``.
  public init(slots: [Slot]? = nil, selectedHotbarSlot: Int = 0) {
    if let count = slots?.count {
      assert(count == Self.slotCount)
    }

    self.slots = slots ?? Array(repeating: Slot(), count: Self.slotCount)
    self.selectedHotbarSlot = selectedHotbarSlot
  }

  /// Gets the slots associated with a particular area of the inventory.
  /// - Returns: The rows of the area, e.g. ``Area/hotbar`` results in a single row, and
  ///   ``Area/armor`` results in 4 rows containing 1 element each.
  public func slots(for area: Area) -> [[Slot]] {
    var rows: [[Slot]] = []
    for y in 0..<area.height {
      var row: [Slot] = []
      for x in 0..<area.width {
        let index = y * area.width + x + area.startIndex
        row.append(slots[index])
      }
      rows.append(row)
    }
    return rows
  }
}
