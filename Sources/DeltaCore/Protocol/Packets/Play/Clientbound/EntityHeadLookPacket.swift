//
//  EntityHeadLookPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct EntityHeadLookPacket: ClientboundPacket {
  static let id: Int = 0x3b
  
  var entityId: Int
  var headYaw: UInt8

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    headYaw = packetReader.readAngle()
  }
}
