//
//  EditBookPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct EditBookPacket: ServerboundPacket {
  static let id: Int = 0x0c
  
  var newBook: ItemStack
  var isSigning: Bool
  var hand: Hand
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeItemStack(newBook)
    writer.writeBool(isSigning)
    writer.writeVarInt(hand.rawValue)
  }
}
