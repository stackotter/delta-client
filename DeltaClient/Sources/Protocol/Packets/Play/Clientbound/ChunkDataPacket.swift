//
//  ChunkDataPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation


struct ChunkDataPacket: ClientboundPacket {
  static let id: Int = 0x21
  
  var chunkData: ChunkData
  
  init(from packetReader: inout PacketReader) throws {
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    chunkData = ChunkData(position: position, reader: packetReader)
  }
  
  func handle(for server: Server) throws {
    server.world?.addChunkData(chunkData)
  }
}
