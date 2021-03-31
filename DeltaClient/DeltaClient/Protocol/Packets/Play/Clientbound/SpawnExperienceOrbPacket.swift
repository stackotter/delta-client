//
//  SpawnExperienceOrbPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/2/21.
//

import Foundation

struct SpawnExperienceOrbPacket: ClientboundPacket {
  static let id: Int = 0x01
  
  var entityId: Int
  var position: EntityPosition
  var count: Int16
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    count = packetReader.readShort()
  }
}
