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

  /// The inventory's contents.
  public var slots: [Slot]
  /// The player's currently selected hotbar slot.
  public var selectedHotbarSlot: Int
  /// The inventory's hotbar.
  public var hotbar: ArraySlice<Slot> {
    slots[Self.hotbarSlotStartIndex...Self.hotbarSlotEndIndex]
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
