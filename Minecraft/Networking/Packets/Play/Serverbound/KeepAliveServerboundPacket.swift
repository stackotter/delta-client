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
  
  func toBytes() -> [UInt8] {
    var writer = PacketWriter(packetId: id)
    writer.writeLong(keepAliveId)
    return writer.pack()
  }
}
