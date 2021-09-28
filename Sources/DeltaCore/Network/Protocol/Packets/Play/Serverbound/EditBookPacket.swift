//
//  EditBookPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct EditBookPacket: ServerboundPacket {
  public static let id: Int = 0x0c
  
  public var newBook: ItemStack
  public var isSigning: Bool
  public var hand: Hand
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeItemStack(newBook)
    writer.writeBool(isSigning)
    writer.writeVarInt(hand.rawValue)
  }
}
