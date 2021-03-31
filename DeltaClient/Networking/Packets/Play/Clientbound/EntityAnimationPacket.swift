//
//  EntityAnimationPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct EntityAnimationPacket: ClientboundPacket {
  static let id: Int = 0x05
  
  var entityId: Int
  var animationId: UInt8
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    animationId = packetReader.readUnsignedByte()
  }
}
