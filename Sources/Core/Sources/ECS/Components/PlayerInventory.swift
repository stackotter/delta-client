import FirebladeECS

/// A component storing the player's inventory. Simply wraps a ``Window`` with some
/// inventory-specific properties and helper methods.
public class PlayerInventory: Component {
  /// The number of slots in a player inventory (including armor and off hand).
  public static let slotCount = 46
  /// The player's inventory's window id.
  public static let windowId = 0

  /// The index of the crafting result slot.
  public static let craftingResultIndex = craftingResultArea.startIndex
  /// The index of the player's off-hand slot.
  public static let offHandIndex = offHandArea.startIndex

  public static let mainArea = WindowArea(
    startIndex: 9,
    width: 9,
    height: 3,
    position: Vec2i(8, 84)
  )

  public static let hotbarArea = WindowArea(
    startIndex: 36,
    width: 9,
    height: 1,
    position: Vec2i(8, 142)
  )

  public static let craftingInputArea = WindowArea(
    startIndex: 1,
    width: 2,
    height: 2,
    position: Vec2i(98, 18),
    kind: .smallCraftingRecipeInput
  )

  public static let craftingResultArea = WindowArea(
    startIndex: 0,
    width: 1,
    height: 1,
    position: Vec2i(154, 28),
    kind: .recipeResult
  )

  public static let armorArea = WindowArea(
    startIndex: 5,
    width: 1,
    height: 4,
    position: Vec2i(8, 8),
    kind: .armor
  )

  public static let offHandArea = WindowArea(
    startIndex: 45,
    width: 1,
    height: 1,
    position: Vec2i(77, 62)
  )

  /// The inventory's window; contains the underlying slots.
  public var window: Window
  /// The player's currently selected hotbar slot.
  public var selectedHotbarSlot: Int

  /// The inventory's main 3 row 9 column area.
  public var mainArea: [[Slot]] {
    window.slots(for: Self.mainArea)
  }

  /// The inventory's crafting input slots.
  public var craftingInputs: [[Slot]] {
    window.slots(for: Self.craftingInputArea)
  }

  // TODO: Choose a casing for hotbar and stick to it (hotbar vs hotBar)
  /// The inventory's hotbar slots.
  public var hotbar: [Slot] {
    window.slots(for: Self.hotbarArea)[0]
  }

  /// The result slot of the inventory's crafting area.
  public var craftingResult: Slot {
    window.slots[Self.craftingResultIndex]
  }

  /// The armor slots.
  public var armorSlots: [Slot] {
    window.slots(for: Self.armorArea).map { row in
      row[0]
    }
  }

  /// The off-hand slot.
  public var offHand: Slot {
    window.slots[Self.offHandIndex]
  }

  /// The item in the currently selected hotbar slot, `nil` if the slot is empty
  /// or the item stack is invalid.
  public var mainHandItem: Item? {
    guard let stack = hotbar[selectedHotbarSlot].stack else {
      return nil
    }

    guard let item = RegistryStore.shared.itemRegistry.item(withId: stack.itemId) else {
      log.warning("Non-existent item with id \(stack.itemId) selected in hotbar")
      return nil
    }

    return item
  }

  /// Creates the player's inventory state.
  /// - Parameter selectedHotbarSlot: Defaults to 0 (the first slot from the left in the main hotbar).
  /// - Precondition: The length of `slots` must match ``PlayerInventory/slotCount``.
  public init(slots: [Slot]? = nil, selectedHotbarSlot: Int = 0) {
    window = Window(
      id: Self.windowId,
      type: .inventory,
      slots: slots
    )

    self.selectedHotbarSlot = selectedHotbarSlot
  }
}
