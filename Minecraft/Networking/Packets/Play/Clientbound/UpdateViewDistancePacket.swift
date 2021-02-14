//
//  UpdateViewDistancePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct UpdateViewDistancePacket: ClientboundPacket {
  static let id: Int = 0x41
  
  var viewDistance: Int32

  init(fromReader packetReader: inout PacketReader) throws {
    viewDistance = packetReader.readVarInt()
  }
}
