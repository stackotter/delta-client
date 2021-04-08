//
//  NameItemPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct NameItemPacket: ServerboundPacket {
  static let id: Int = 0x1f
  
  var itemName: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeString(itemName)
  }
}
