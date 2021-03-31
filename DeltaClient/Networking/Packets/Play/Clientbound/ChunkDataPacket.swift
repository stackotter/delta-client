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
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    chunkData = ChunkData(position: position, buf: packetReader.buf)
  }
  
  // TODO: clean up how downloading terrain is triggered to end
  func handle(for server: Server) throws {
    if let world = server.currentWorld {
      world.addChunkData(chunkData, unpack: !world.downloadingTerrain)
      if world.downloadingTerrain {
        let viewDiameter = server.config.viewDistance * 2 + (3)
        let targetNumChunks = viewDiameter * viewDiameter
        if world.packedChunks.count == targetNumChunks {
          Logger.log("unpacking chunks")
          do {
            try world.unpackChunks()
          } catch {
            Logger.error("failed to unpack chunks")
          }
        }
      }
    }
  }
}
