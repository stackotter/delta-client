//
//  EntityPositionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct EntityPositionPacket: ClientboundPacket {
  static let id: Int = 0x28
  
  var entityId: Int32
  var deltaX: Int16
  var deltaY: Int16
  var deltaZ: Int16
  var onGround: Bool
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    onGround = packetReader.readBool()
  }
}
