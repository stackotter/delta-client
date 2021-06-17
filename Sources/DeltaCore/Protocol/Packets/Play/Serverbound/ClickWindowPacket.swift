//
//  ClickWindowPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ClickWindowPacket: ServerboundPacket {
  static let id: Int = 0x09
  
  var windowId: UInt8
  var slot: Int16
  var button: Int8
  var actionNumber: Int16
  var mode: Int32
  var clickedItem: ItemStack
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
    writer.writeShort(slot)
    writer.writeByte(button)
    writer.writeShort(actionNumber)
    writer.writeVarInt(mode)
    writer.writeItemStack(clickedItem)
  }
}
