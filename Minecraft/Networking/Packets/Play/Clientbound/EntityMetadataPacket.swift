//
//  EntityMetadataPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct EntityMetadataPacket: ClientboundPacket {
  static let id: Int = 0x44
  
  var entityId: Int

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    // IMPLEMENT: the rest of this packet
  }
}
