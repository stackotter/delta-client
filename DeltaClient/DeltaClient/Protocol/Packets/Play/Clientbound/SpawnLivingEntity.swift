//
//  SpawnLivingEntity.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/2/21.
//

import Foundation

struct SpawnLivingEntity: ClientboundPacket {
  static let id: Int = 0x02
  
  var entityId: Int
  var entityUUID: UUID
  var type: Int
  var position: EntityPosition
  var rotation: EntityRotation
  var headPitch: UInt8
  var velocity: EntityVelocity
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
    headPitch = packetReader.readAngle()
    velocity = packetReader.readEntityVelocity()
  }
}
