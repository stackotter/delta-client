//
//  BlockActionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockActionPacket: ClientboundPacket {
  static let id: Int = 0x0a
  
  var location: Position
  var actionId: UInt8
  var actionParam: UInt8
  var blockType: Int32 // this is the block id not the block state
  
  init(fromReader packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    actionId = packetReader.readUnsignedByte()
    actionParam = packetReader.readUnsignedByte()
    blockType = packetReader.readVarInt()
  }
}
