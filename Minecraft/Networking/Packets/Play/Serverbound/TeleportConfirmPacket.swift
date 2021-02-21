//
//  TeleportConfirmPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct TeleportConfirmPacket: ServerboundPacket {
  static let id: Int = 0x00
  
  var teleportId: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(teleportId)
  }
}
