//
//  OpenHorseWindowPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct OpenHorseWindowPacket: ClientboundPacket {
  static let id: Int = 0x1f
  
  var windowId: Int8
  var numberOfSlots: Int32
  var entityId: Int32
  
  init(fromReader packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    numberOfSlots = packetReader.readVarInt()
    entityId = packetReader.readInt()
  }
}
