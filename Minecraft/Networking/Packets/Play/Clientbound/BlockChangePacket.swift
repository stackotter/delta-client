//
//  BlockChangePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockChangePacket: Packet {
  typealias PacketType = BlockChangePacket
  static let id: Int = 0x0b
  
  var location: Position
  var blockId: Int32 // the new block state id
  
  init(fromReader packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    blockId = packetReader.readVarInt()
  }
}
