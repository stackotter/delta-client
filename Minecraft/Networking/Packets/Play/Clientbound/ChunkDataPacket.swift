//
//  ChunkDataPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

struct ChunkDataPacket: ClientboundPacket {
  static let id: Int = 0x21
  
  var chunkData: ChunkData
  
  init(from packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    chunkData = ChunkData(position: position, buf: packetReader.buf)
  }
  
  // TODO_LATER: clean up how downloading terrain is triggered to end
  func handle(for server: Server) throws {
    server.currentWorld.addChunkData(chunkData, unpack: !server.downloadingTerrain)
    if server.downloadingTerrain {
      let viewDiameter = server.config.viewDistance * 2 + 1
      let targetNumChunks = viewDiameter * viewDiameter
      if server.currentWorld.packedChunks.count == targetNumChunks {
        server.downloadingTerrain = false
        Logger.log("downloaded terrain")
        Logger.log("unpacking chunks")
        do {
          try server.currentWorld.unpackChunks() // TODO_LATER: fix to use view distance
        } catch {
          Logger.log("failed to unpack chunks after downloading terrain")
        }
      }
    }
  }
}
