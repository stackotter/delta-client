//
//  KeepAliveClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation
import os

struct KeepAliveClientboundPacket: ClientboundPacket {
  static let id: Int = 0x20
  
  var keepAliveId: Int64
  
  init(from packetReader: inout PacketReader) throws {
    keepAliveId = packetReader.readLong()
  }
  
  func handle(for server: Server) throws {
    let keepAlive = KeepAliveServerBoundPacket(keepAliveId: keepAliveId)
    server.sendPacket(keepAlive)
  }
}
