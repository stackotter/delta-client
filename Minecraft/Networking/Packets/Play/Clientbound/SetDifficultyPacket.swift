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
  
  static func from(_ packetReader: inout PacketReader) -> SetDifficultyPacket {
    let difficulty = Difficulty(rawValue: packetReader.readUnsignedByte())!
    let isLocked = packetReader.readBool()
    return SetDifficultyPacket(difficulty: difficulty, isLocked: isLocked)
  }
}

