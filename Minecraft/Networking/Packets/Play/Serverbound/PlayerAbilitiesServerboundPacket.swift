//
//  PlayerAbilitiesServerboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerAbilitiesServerboundPacket: ServerboundPacket {
  static let id: Int = 0x1a
  
  var flags: PlayerAbilities
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(flags.rawValue)
  }
}
