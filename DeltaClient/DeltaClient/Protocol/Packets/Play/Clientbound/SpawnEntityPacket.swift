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
  
  // TODO_LATER: figure out all the entity madness
  init(from packetReader: inout PacketReader) {
    entityId = packetReader.readVarInt()
    objectUUID = packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation(pitchFirst: true) // TODO_LATER: seems a lil sus that this is the only packet that has pitch and yaw in the other order
    data = packetReader.readInt()
    
    velocity = nil
    if data > 0 {
      velocity = packetReader.readEntityVelocity()
    }
  }
}
