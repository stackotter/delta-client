//
//  BlockBreakAnimationPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockBreakAnimationPacket: ClientboundPacket {
  static let id: Int = 0x08
  
  var entityId: Int
  var location: Position
  var destroyStage: Int8
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    location = packetReader.readPosition()
    destroyStage = packetReader.readByte()
  }
}
