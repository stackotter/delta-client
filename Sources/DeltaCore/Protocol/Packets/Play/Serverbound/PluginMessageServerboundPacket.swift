//
//  PluginMessageServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PluginMessageServerboundPacket: ServerboundPacket {
  static let id: Int = 0x0b
  
  var channel: Identifier
  var data: [UInt8]
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeIdentifier(channel)
    writer.writeByteArray(data)
  }
}
