//
//  ItemStack.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

struct ItemStack {
  var item: Item?
  var count: Int
  
  var isEmpty: Bool {
    return item == nil
  }
  
  init(fromSlot slot: Slot) {
    if slot.present {
      self.item = Item(id: slot.itemId!, nbt: slot.nbt!)
      self.count = slot.itemCount!
    } else {
      self.count = 0
    }
  }
  
  func toSlot() -> Slot {
    if !isEmpty {
      var nbt: NBTCompound
      if item!.nbt == nil {
        nbt = NBTCompound(isRoot: true)
      } else {
        nbt = item!.nbt!
      }
      return Slot(itemId: item!.id, itemCount: count, nbt: nbt)
    } else {
      return Slot()
    }
  }
}
