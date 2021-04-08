//
//  UpdateCommandBlockMinecartPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UpdateCommandBlockMinecartPacket: ServerboundPacket {
  static let id: Int = 0x26
  
  var entityId: Int32
  var command: String
  var trackOutput: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(entityId)
    writer.writeString(command)
    writer.writeBool(trackOutput)
  }
}
