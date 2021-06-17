//
//  PickItemPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PickItemPacket: ServerboundPacket {
  static let id: Int = 0x18
  
  var slotToUse: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(slotToUse)
  }
}
