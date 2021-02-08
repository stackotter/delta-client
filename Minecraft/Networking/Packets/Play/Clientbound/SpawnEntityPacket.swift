//
//  SpawnEntityPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 8/2/21.
//

import Foundation

struct SpawnEntityPacket: Packet {
  typealias PacketType = SpawnEntityPacket
  static let id: Int = 0x00
  
  var entityId: Int32
  var objectUUID: UUID
  var type: Int32
  var position: EntityPosition
  var rotation: EntityRotation
  var data: Int32
  var velocity: EntityVelocity?
  
  // TODO: figure out all the entity madness
  init(fromReader packetReader: inout PacketReader) {
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
