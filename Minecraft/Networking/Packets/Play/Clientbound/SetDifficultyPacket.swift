//
//  SetDifficulty.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct SetDifficultyPacket: Packet {
  typealias PacketType = SetDifficultyPacket
  static let id: Int = 0x0d
  
  var difficulty: Difficulty
  var isLocked: Bool
  
  init(fromReader packetReader: inout PacketReader) {
    difficulty = Difficulty(rawValue: packetReader.readUnsignedByte())!
    isLocked = packetReader.readBool()
  }
}

