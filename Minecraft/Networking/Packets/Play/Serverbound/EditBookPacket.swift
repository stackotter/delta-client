//
//  EditBookPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct EditBookPacket: ServerboundPacket {
  static let id: Int = 0x0c
  
  var newBook: Slot
  var isSigning: Bool
  var hand: Hand
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeSlot(newBook)
    writer.writeBool(isSigning)
    writer.writeVarInt(hand.rawValue)
  }
}
