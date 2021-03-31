//
//  ChatMessageServerboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ChatMessageServerboundPacket: ServerboundPacket {
  static let id: Int = 0x03
  
  var message: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeString(message)
  }
}
