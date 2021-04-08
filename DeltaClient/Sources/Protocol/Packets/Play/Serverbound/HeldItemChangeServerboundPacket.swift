//
//  HeldItemChangeServerboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct HeldItemChangeServerboundPacket: ServerboundPacket {
  static let id: Int = 0x24
  
  var slot: Int16
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeShort(slot)
  }
}
