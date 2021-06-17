//
//  RemoveEntityEffectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct RemoveEntityEffectPacket: ClientboundPacket {
  static let id: Int = 0x38
  
  var entityId: Int
  var effectId: Int8

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    effectId = packetReader.readByte()
  }
}
