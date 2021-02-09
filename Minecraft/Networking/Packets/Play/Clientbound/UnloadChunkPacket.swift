//
//  UnloadChunkPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct UnloadChunkPacket: Packet {
  typealias PacketType = UnloadChunkPacket
  static let id: Int = 0x1d
  
  var chunkPosition: ChunkPosition
  
  init(fromReader packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
}
