//
//  KeepAliveClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct KeepAliveClientboundPacket: Packet {
  typealias PacketType = KeepAliveClientboundPacket
  static let id: Int = 0x20
  
  var keepAliveId: Int64
  
  init(fromReader packetReader: inout PacketReader) throws {
    keepAliveId = packetReader.readLong()
  }
}
