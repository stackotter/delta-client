//
//  DisplayScoreboardPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct DisplayScoreboardPacket: ClientboundPacket {
  static let id: Int = 0x43
  
  var position: Int8
  var scoreName: String

  init(from packetReader: inout PacketReader) throws {
    position = packetReader.readByte()
    scoreName = try packetReader.readString()
  }
}
