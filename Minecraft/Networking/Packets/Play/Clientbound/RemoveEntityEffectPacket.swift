//
//  RemoveEntityEffectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct RemoveEntityEffectPacket: ClientboundPacket {
  static let id: Int = 0x38
  
  var entityId: Int32
  var effectId: Int8

  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    effectId = packetReader.readByte()
  }
}
