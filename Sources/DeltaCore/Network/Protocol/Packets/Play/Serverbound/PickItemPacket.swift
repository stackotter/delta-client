//
//  PickItemPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct PickItemPacket: ServerboundPacket {
  public static let id: Int = 0x18
  
  public var slotToUse: Int32
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(slotToUse)
  }
}
