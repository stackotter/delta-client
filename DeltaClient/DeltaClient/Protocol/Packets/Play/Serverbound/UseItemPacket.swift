//
//  UseItemPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UseItemPacket: ServerboundPacket {
  static let id: Int = 0x2e
  
  var hand: Hand
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(hand.rawValue)
  }
}
