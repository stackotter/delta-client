//
//  EntityPositionAndRotationPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct EntityPositionAndRotationPacket: ClientboundPacket {
  static let id: Int = 0x29

  var entityId: Int
  var deltaX: Int16
  var deltaY: Int16
  var deltaZ: Int16
  var rotation: EntityRotation
  var onGround: Bool
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
}
