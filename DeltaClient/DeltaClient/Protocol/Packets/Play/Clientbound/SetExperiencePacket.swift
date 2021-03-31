//
//  SetExperiencePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SetExperiencePacket: ClientboundPacket {
  static let id: Int = 0x48
  
  var experienceBar: Float
  var level: Int
  var totalExperience: Int

  init(from packetReader: inout PacketReader) throws {
    experienceBar = packetReader.readFloat()
    level = packetReader.readVarInt()
    totalExperience = packetReader.readVarInt()
  }
  
  func handle(for server: Server) throws {
    server.player.experienceBar = experienceBar
    server.player.experienceLevel = level
    server.player.totalExperience = totalExperience
  }
}
