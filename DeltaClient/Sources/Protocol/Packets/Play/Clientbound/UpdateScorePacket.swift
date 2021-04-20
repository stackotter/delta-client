//
//  UpdateScorePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct UpdateScorePacket: ClientboundPacket {
  static let id: Int = 0x4d
  
  var entityName: String
  var action: Int8
  var objectiveName: String
  var value: Int?
  
  init(from packetReader: inout PacketReader) throws {
    // TODO: implement strings with max length in packetreader
    entityName = try packetReader.readString()
    action = packetReader.readByte()
    objectiveName = try packetReader.readString()
    if action != 1 {
      value = packetReader.readVarInt()
    }
  }
}
