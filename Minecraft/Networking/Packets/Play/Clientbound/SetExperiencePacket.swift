//
//  SetExperiencePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SetExperiencePacket: ClientboundPacket {
  static let id: Int = 0x48
  
  var experienceBar: Float
  var level: Int32
  var totalExperience: Int32

  init(from packetReader: inout PacketReader) throws {
    experienceBar = packetReader.readFloat()
    level = packetReader.readVarInt()
    totalExperience = packetReader.readVarInt()
  }
}
