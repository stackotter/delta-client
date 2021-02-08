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
  
  static func from(_ packetReader: inout PacketReader) throws -> SpawnEntityPacket {
    let entityId = packetReader.readVarInt()
    let objectUUID = packetReader.readUUID()
    let type = packetReader.readVarInt()
    
    let x = packetReader.readDouble()
    let y = packetReader.readDouble()
    let z = packetReader.readDouble()
    let position = EntityPosition(x: x, y: y, z: z)
    
    let pitch = packetReader.readAngle()
    let yaw = packetReader.readAngle()
    let rotation: EntityRotation = EntityRotation(pitch: pitch, yaw: yaw)
    
    let data = packetReader.readInt()
    
    let velocityX = packetReader.readShort()
    let velocityY = packetReader.readShort()
    let velocityZ = packetReader.readShort()
    var velocity: EntityVelocity? = nil
    if data > 0 {
      velocity = EntityVelocity(x: velocityX, y: velocityY, z: velocityZ)
    }
    return SpawnEntityPacket(entityId: entityId, objectUUID: objectUUID, type: type, position: position, rotation: rotation, data: data, velocity: velocity)
  }
}
