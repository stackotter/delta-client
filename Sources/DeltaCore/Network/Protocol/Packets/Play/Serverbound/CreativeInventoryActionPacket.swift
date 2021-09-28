//
//  CreativeInventoryActionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct CreativeInventoryActionPacket: ServerboundPacket {
  public static let id: Int = 0x27
  
  public var slot: Int16
  public var clickedItem: ItemStack
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeShort(slot)
    writer.writeItemStack(clickedItem)
  }
}
