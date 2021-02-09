//
//  BlockBreakAnimationPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockBreakAnimationPacket: Packet {
  typealias PacketType = BlockBreakAnimationPacket
  static let id: Int = 0x08
  
  var entityId: Int32
  var location: Position
  var destroyStage: Int8
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    location = packetReader.readPosition()
    destroyStage = packetReader.readByte()
  }
}
