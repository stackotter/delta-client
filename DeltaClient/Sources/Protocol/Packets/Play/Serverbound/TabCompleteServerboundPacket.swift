//
//  TabCompleteServerboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct TabCompleteServerboundPacket: ServerboundPacket {
  static let id: Int = 0x06
  
  var transactionId: Int32
  var text: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writeString(text)
  }
}
