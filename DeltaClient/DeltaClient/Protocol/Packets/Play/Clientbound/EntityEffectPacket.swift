//
//  EntityEffectPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct EntityEffectPacket: ClientboundPacket {
  static let id: Int = 0x59
  
  var entityId: Int
  var effectId: Int8
  var amplifier: Int8
  var duration: Int
  var flags: Int8

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    effectId = packetReader.readByte()
    amplifier = packetReader.readByte()
    duration = packetReader.readVarInt()
    flags = packetReader.readByte()
  }
}
