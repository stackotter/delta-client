//
//  ScoreboardObjectivePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct ScoreboardObjectivePacket: ClientboundPacket {
  static let id: Int = 0x4a
  
  var objectiveName: String
  var mode: UInt8
  var objectiveValue: ChatComponent?
  var type: Int32?

  init(fromReader packetReader: inout PacketReader) throws {
    objectiveName = packetReader.readString()
    mode = packetReader.readUnsignedByte()
    if mode == 0 || mode == 2 {
      objectiveValue = packetReader.readChat()
      type = packetReader.readVarInt()
    }
  }
}
