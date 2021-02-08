//
//  UpdateViewPositionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

struct UpdateViewPositionPacket: Packet {
  typealias PacketType = UpdateViewPositionPacket
  static let id: Int = 0x40
  
  var chunkPosition: ChunkPosition
  
  init(fromReader packetReader: inout PacketReader) {
    let chunkX = packetReader.readVarInt()
    let chunkZ = packetReader.readVarInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
}
