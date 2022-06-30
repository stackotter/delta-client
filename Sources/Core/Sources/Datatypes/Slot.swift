/// An inventory slot.
public struct Slot {
  /// The slot's content if any.
  public var stack: ItemStack?

  /// Creates a new slot.
  /// - Parameter stack: The slot's content.
  public init(_ stack: ItemStack? = nil) {
    self.stack = stack
  }
}
