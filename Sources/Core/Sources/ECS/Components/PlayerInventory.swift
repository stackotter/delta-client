import FirebladeECS

/// A component storing the player's inventory.
public class PlayerInventory: Component {
  /// The number of slots in a player inventory (including armor and off hand).
  public static let slotCount = 46
  /// The player's inventory's window id.
  public static let windowId = 0
  /// The index of the first hotbar slot.
  public static let hotbarSlotStartIndex = 36
  /// The index of the last hotbar slot.
  public static let hotbarSlotEndIndex = 44

  /// The index of the first slot of the main inventory area (the 3 by 9 grid).
  public static let mainAreaStartIndex = 9
  /// The width of the main area.
  public static let mainAreaWidth = 9
  /// The height of the main area.
  public static let mainAreaHeight = 3

  /// The index of the first slot of the inventory's crafting area.
  public static let craftingAreaStartIndex = 1
  /// The width of the inventory's crafting area.
  public static let craftingAreaWidth = 2
  /// The height of the inventory's crafting area.
  public static let craftingAreaHeight = 2
  /// The index of the crafting result slot.
  public static let craftingResultIndex = 0

  /// The index of the first armor slot.
  public static let armorSlotsStartIndex = 5
  /// The number of armor slots.
  public static let armorSlotsCount = 4

  /// The index of the player's off-hand slot.
  public static let offHandIndex = 45

  /// The inventory's contents.
  public var slots: [Slot]
  /// The player's currently selected hotbar slot.
  public var selectedHotbarSlot: Int
  /// The inventory's hotbar.
  public var hotbar: [Slot] {
    return Array(slots[Self.hotbarSlotStartIndex...Self.hotbarSlotEndIndex])
  }

  /// The rows of the main 3 by 9 area of the inventory.
  public var mainArea: [[Slot]] {
    var rows: [[Slot]] = []
    for y in 0..<Self.mainAreaHeight {
      var row: [Slot] = []
      for x in 0..<Self.mainAreaWidth {
        let index = y * Self.mainAreaWidth + x + Self.mainAreaStartIndex
        row.append(slots[index])
      }
      rows.append(row)
    }
    return rows
  }

  /// The rows of the 2 by 2 crafting area of the inventory.
  public var craftingArea: [[Slot]] {
    var rows: [[Slot]] = []
    for y in 0..<Self.craftingAreaHeight {
      var row: [Slot] = []
      for x in 0..<Self.craftingAreaWidth {
        let index = y * Self.craftingAreaWidth + x + Self.craftingAreaStartIndex
        row.append(slots[index])
      }
      rows.append(row)
    }
    return rows
  }

  /// The result slot of the inventory's crafting area.
  public var craftingResult: Slot {
    return slots[Self.craftingResultIndex]
  }

  /// The armor slots.
  public var armorSlots: [Slot] {
    return Array(slots[Self.armorSlotsStartIndex..<Self.armorSlotsStartIndex + Self.armorSlotsCount])
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
}
