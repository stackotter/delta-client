//
//  HeldItemChangePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct HeldItemChangePacket: ClientboundPacket {
  static let id: Int = 0x3f
  
  var slot: Int8
  
  init(fromReader packetReader: inout PacketReader) {
    slot = packetReader.readByte()
  }
  
  func handle(for server: Server) throws {
    server.player.hotbarSlot = slot
  }
}
