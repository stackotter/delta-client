//
//  EntityMovementPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct EntityMovementPacket: ClientboundPacket {
  static let id: Int = 0x2b
  
  var entityId: Int32
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
  }
}
