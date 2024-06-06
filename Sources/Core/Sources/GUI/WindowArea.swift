/// An area of a GUI window; a grid of slots. Only handles areas where the rows
/// are stored one after another in the window's slot array.
public struct WindowArea {
  /// Index of the first slot in the area.
  public var startIndex: Int
  /// Number of slots wide.
  public var width: Int
  /// Number of slots high.
  public var height: Int
  /// The position of the area within its window.
  public var position: Vec2i
  /// The kind of window area (determines its behaviour).
  public var kind: Kind?

  public init(
    startIndex: Int,
    width: Int,
    height: Int,
    position: Vec2i,
    kind: WindowArea.Kind? = nil
  ) {
    self.startIndex = startIndex
    self.width = width
    self.height = height
    self.position = position
    self.kind = kind
  }

  /// Gets the position of a slot (given as an index in the window's slots array)
  /// if it lies within this area.
  public func position(ofWindowSlot slotIndex: Int) -> Vec2i? {
    let endIndex = startIndex + width * height
    if slotIndex >= startIndex && slotIndex < endIndex {
      let position = Vec2i(
        (slotIndex - startIndex) % width,
        (slotIndex - startIndex) / width
      )
      return position
    }
    return nil
  }

  public enum Kind {
    /// A 9x3 area synced with the player's inventory.
    case inventorySynced
    /// A 9x1 area synced with the player's hotbar.
    case hotbarSynced
    /// A full 3x3 crafting recipe input area.
    case fullCraftingRecipeInput
    /// A small 2x2 crafting recipe input area.
    case smallCraftingRecipeInput
    /// A 1x1 heat recipe (e.g. furnace recipe) input area.
    case heatRecipeInput
    /// A 1x1 recipe result output area.
    case recipeResult
    /// A 1x1 heat recipe fuel input area (e.g. furnace fuel slot).
    case heatRecipeFuel
    /// The 1x1 anvil input slot on the left.
    case firstAnvilInput
    /// The 1x1 anvil input slot on the right.
    case secondAnvilInput
    /// The 1x4 armor area in the player inventory.
    case armor
  }
}
