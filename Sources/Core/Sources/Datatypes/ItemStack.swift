import Foundation

// TODO: Refactor item stacks and recipes
public struct ItemStack {
  public var itemId: Int?
  public var itemNBT: NBT.Compound?
  public var count: Int

  public var isEmpty: Bool {
    return itemId == nil
  }

  public init() {
    self.count = 0
  }

  public init(itemId: Int, itemCount: Int, nbt: NBT.Compound) {
    self.itemId = itemId
    self.itemNBT = nbt
    self.count = itemCount
  }
}
