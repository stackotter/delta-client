//
//  EntityTeleportPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct EntityTeleportPacket: ClientboundPacket {
  static let id: Int = 0x56
  
  var entityId: Int
  var position: EntityPosition
  var rotation: EntityRotation
  var onGround: Bool

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
}
