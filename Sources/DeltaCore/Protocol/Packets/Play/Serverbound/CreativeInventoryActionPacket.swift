//
//  CreativeInventoryActionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct CreativeInventoryActionPacket: ServerboundPacket {
  static let id: Int = 0x27
  
  var slot: Int16
  var clickedItem: ItemStack
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeShort(slot)
    writer.writeItemStack(clickedItem)
  }
}
