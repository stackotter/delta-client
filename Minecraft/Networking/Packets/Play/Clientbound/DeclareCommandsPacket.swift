//
//  DeclareCommandsPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct DeclareCommandsPacket: ClientboundPacket {
  static let id: Int = 0x11
  
  init(fromReader packetReader: inout PacketReader) throws {
    // IMPLEMENT: declare commands packet
  }
}
