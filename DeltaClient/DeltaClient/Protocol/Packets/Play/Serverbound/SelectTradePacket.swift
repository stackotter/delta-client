//
//  SelectTradePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SelectTradePacket: ServerboundPacket {
  static let id: Int = 0x22
  
  var selectedSlot: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(selectedSlot)
  }
}
