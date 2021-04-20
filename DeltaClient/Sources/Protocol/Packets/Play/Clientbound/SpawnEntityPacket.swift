//
//  SpawnEntityPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/2/21.
//

import Foundation

struct SpawnEntityPacket: ClientboundPacket {
  static let id: Int = 0x00
  
  var entityId: Int
  var objectUUID: UUID
  var type: Int
  var position: EntityPosition
  var rotation: EntityRotation
  var data: Int
  var velocity: EntityVelocity?
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    objectUUID = try packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    // seems a lil sus that this is the only packet that has pitch and yaw in the other order
    rotation = packetReader.readEntityRotation(pitchFirst: true)
    data = packetReader.readInt()
    
    velocity = nil
    if data > 0 {
      velocity = packetReader.readEntityVelocity()
    }
  }
}
