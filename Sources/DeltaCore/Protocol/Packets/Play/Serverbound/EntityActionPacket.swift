//
//  EntityActionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct EntityActionPacket: ServerboundPacket {
  static let id: Int = 0x1c
  
  var entityId: Int32
  var action: PlayerEntityAction
  var jumpBoost: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(entityId)
    writer.writeVarInt(action.rawValue)
    writer.writeVarInt(jumpBoost)
  }
}
