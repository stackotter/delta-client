//
//  ItemStack.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 29/12/20.
//

import Foundation

struct ItemStack {
  var item: Item?
  var count: Int
  
  var isEmpty: Bool {
    return item == nil
  }
  
  init() {
    self.count = 0
  }
  
  init(itemId: Int, itemCount: Int, nbt: NBTCompound) {
    self.item = Item(id: itemId, nbt: nbt)
    self.count = itemCount
  }
}
