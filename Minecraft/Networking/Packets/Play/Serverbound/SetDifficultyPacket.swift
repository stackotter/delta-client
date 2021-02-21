//
//  SetDifficultyPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SetDifficultyPacket: ServerboundPacket {
  static let id: Int = 0x02
  
  var newDifficulty: Difficulty
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(newDifficulty.rawValue)
  }
}
