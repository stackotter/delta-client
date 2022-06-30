import Foundation

// TODO: Refactor item stacks and recipes
/// A stack of items.
public struct ItemStack {
  /// The item that is stacked.
  public var itemId: Int
  /// The number of items in the stack.
  public var count: Int
  /// Any extra properties the items have.
  public var nbt: NBT.Compound // TODO: refactor this away

  /// Creates a new item stack.
  public init(itemId: Int, itemCount: Int, nbt: NBT.Compound? = nil) {
    self.itemId = itemId
    self.count = itemCount
    self.nbt = nbt ?? NBT.Compound()
  }
}
