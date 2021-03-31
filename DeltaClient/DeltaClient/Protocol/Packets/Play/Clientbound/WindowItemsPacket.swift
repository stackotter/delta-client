//
//  WindowItemsPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct WindowItemsPacket: ClientboundPacket {
  static let id: Int = 0x14
  
  var windowId: UInt8
  var slotData: [ItemStack]
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readUnsignedByte()
    
    slotData = []
    let count = packetReader.readShort()
    for _ in 0..<count {
      let slot = try packetReader.readItemStack()
      slotData.append(slot)
    }
  }
}
