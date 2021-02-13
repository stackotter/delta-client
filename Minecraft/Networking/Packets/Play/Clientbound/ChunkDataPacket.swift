//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: ClientboundPacket {
  static let id: Int = 0x21
  
  var chunk: Chunk
  
  init(fromReader packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    // TODO: merge chunk data into here? unless it can be used to help multithread chunk unpacking
    let chunkData = ChunkData(position: position, data: packetReader.buf)
    chunk = try chunkData.unpack()
  }
  
  func handle(for server: Server) {
    server.currentWorld!.addChunk(data: chunk)
  }
}
