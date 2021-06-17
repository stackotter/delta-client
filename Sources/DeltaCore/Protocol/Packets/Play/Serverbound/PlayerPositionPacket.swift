//
//  PlayerPositionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerPositionPacket: ServerboundPacket {
  static let id: Int = 0x12
  
  var position: EntityPosition // y is feet position
  var onGround: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeBool(onGround)
  }
}
