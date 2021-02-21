//
//  ServerDifficultyPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct ServerDifficultyPacket: ClientboundPacket {
  static let id: Int = 0x0d
  
  var difficulty: Difficulty
  var isLocked: Bool
  
  init(from packetReader: inout PacketReader) {
    difficulty = Difficulty(rawValue: packetReader.readUnsignedByte())!
    isLocked = packetReader.readBool()
  }
}

