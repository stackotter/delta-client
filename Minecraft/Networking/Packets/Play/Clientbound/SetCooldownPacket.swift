//
//  SetCooldownPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct SetCooldownPacket: ClientboundPacket {
  static let id: Int = 0x17
  
  var itemId: Int32
  var cooldownTicks: Int32
  
  init(from packetReader: inout PacketReader) throws {
    itemId = packetReader.readVarInt()
    cooldownTicks = packetReader.readVarInt()
  }
}
