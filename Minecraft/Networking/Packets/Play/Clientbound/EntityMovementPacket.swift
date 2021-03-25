//
//  EntityMovementPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct EntityMovementPacket: ClientboundPacket {
  static let id: Int = 0x2b
  
  var entityId: Int
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
  }
}
