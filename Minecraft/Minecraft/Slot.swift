//
//  Slot.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 29/12/20.
//

import Foundation

struct Slot {
  let present: Bool
  let itemId: Int?
  let itemCount: Int?
  let nbt: NBTCompound?
}
