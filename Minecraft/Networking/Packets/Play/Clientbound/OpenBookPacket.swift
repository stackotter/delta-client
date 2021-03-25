//
//  OpenBookPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct OpenBookPacket: ClientboundPacket {
  static let id: Int = 0x2d
  
  var hand: Int
  
  init(from packetReader: inout PacketReader) throws {
    hand = packetReader.readVarInt()
  }
}
