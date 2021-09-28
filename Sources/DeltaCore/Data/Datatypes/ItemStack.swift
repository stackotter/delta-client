//
//  ItemStack.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 29/12/20.
//

import Foundation

public struct ItemStack {
  public var item: Item?
  public var count: Int
  
  public var isEmpty: Bool {
    return item == nil
  }
  
  public init() {
    self.count = 0
  }
  
  public init(itemId: Int, itemCount: Int, nbt: NBT.Compound) {
    self.item = Item(id: itemId, nbt: nbt)
    self.count = itemCount
  }
}
