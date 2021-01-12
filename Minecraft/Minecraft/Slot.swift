//
//  Slot.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 29/12/20.
//

import Foundation

struct Slot {
  var present: Bool
  var itemId: Int? = nil
  var itemCount: Int? = nil
  var nbt: NBTCompound? = nil
  
  init() {
    self.present = false
  }
  
  init(itemId: Int, itemCount: Int, nbt: NBTCompound) {
    self.present = true
    self.itemId = itemId
    self.itemCount = itemCount
    self.nbt = nbt
  }
  
  init(present: Bool, itemId: Int?, itemCount: Int?, nbt: NBTCompound?) {
    self.present = present
    self.itemId = itemId
    self.itemCount = itemCount
    self.nbt = nbt
  }
}
