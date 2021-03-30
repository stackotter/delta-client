//
//  BlockChangePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockChangePacket: ClientboundPacket {
  static let id: Int = 0x0b
  
  var location: Position
  var blockId: Int // the new block state id
  
  init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    blockId = packetReader.readVarInt()
  }
  
  func handle(for server: Server) throws {
    server.currentWorld?.setBlock(at: location, to: UInt16(blockId))
  }
}
