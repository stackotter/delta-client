//
//  GenerateStructurePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct GenerateStructurePacket: ServerboundPacket {
  static let id: Int = 0x0f
  
  var location: Position
  var levels: Int32
  var keepJigsaws: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeVarInt(levels)
    writer.writeBool(keepJigsaws)
  }
}
