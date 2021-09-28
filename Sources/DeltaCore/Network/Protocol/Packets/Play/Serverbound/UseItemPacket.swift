//
//  UseItemPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct UseItemPacket: ServerboundPacket {
  public static let id: Int = 0x2e
  
  public var hand: Hand
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(hand.rawValue)
  }
}
