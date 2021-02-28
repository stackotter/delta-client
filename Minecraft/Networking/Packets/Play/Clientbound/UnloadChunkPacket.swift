//
//  UnloadChunkPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct UnloadChunkPacket: ClientboundPacket {
  static let id: Int = 0x1d
  
  var chunkPosition: ChunkPosition
  
  init(from packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  func handle(for server: Server) {
    server.currentWorld.removeChunk(at: chunkPosition)
  }
}
