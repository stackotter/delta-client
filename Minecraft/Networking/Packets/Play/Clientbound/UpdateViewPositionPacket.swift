//
//  UpdateViewPositionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

struct UpdateViewPositionPacket: ClientboundPacket {
  static let id: Int = 0x40
  
  var chunkPosition: ChunkPosition
  
  init(fromReader packetReader: inout PacketReader) {
    let chunkX = packetReader.readVarInt()
    let chunkZ = packetReader.readVarInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  func handle(for server: Server) throws {
    server.player.chunkPosition = chunkPosition
    // TODO_LATER: trigger world to recalculate which chunks should be rendered (if a circle is decided on for chunk rendering)
  }
}
