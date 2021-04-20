//
//  SpawnPlayerPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct SpawnPlayerPacket: ClientboundPacket {
  static let id: Int = 0x04
  
  var entityId: Int
  var playerUUID: UUID
  var position: EntityPosition
  var rotation: EntityRotation
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    playerUUID = try packetReader.readUUID()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
  }
}
