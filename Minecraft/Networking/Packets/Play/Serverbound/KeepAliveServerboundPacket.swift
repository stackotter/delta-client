//
//  KeepAliveServerboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct KeepAliveServerBoundPacket: ServerboundPacket {
  static var id: Int = 0x10
  
  var keepAliveId: Int64
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeLong(keepAliveId)
  }
}
