import FirebladeECS

/// A component storing the player's inventory.
public class PlayerInventory: Component {
  /// The player's currently selected hotbar slot.
  public var selectedHotbarSlot: Int

  /// Creates the player's inventory state.
  /// - Parameter selectedHotbarSlot: Defaults to 0 (the first slot from the left in the main hotbar).
  public init(selectedHotbarSlot: Int = 0) {
    self.selectedHotbarSlot = selectedHotbarSlot
  }
}
