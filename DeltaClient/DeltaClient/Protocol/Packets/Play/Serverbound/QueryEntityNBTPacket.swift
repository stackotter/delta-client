//
//  QueryEntityNBTPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct QueryEntityNBTPacket: ServerboundPacket {
  static let id: Int = 0x0d
  
  var transactionId: Int32
  var entityId: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writeVarInt(entityId)
  }
}
