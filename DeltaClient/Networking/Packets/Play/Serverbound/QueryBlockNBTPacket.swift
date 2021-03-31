//
//  QueryBlockNBTPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct QueryBlockNBTPacket: ServerboundPacket {
  static let id: Int = 0x01
  
  var transactionId: Int32
  var location: Position
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writePosition(location)
  }
}
