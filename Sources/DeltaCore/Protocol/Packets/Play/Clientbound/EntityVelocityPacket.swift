//
//  EntityVelocityPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct EntityVelocityPacket: ClientboundPacket {
  static let id: Int = 0x46
  
  var entityId: Int
  var velocity: EntityVelocity

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    velocity = packetReader.readEntityVelocity()
  }
}
