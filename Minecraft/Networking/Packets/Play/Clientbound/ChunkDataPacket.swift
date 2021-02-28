//
//  ChunkDataPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: ClientboundPacket {
  static let id: Int = 0x21
  
//  var chunk: Chunk
  var data: Data
  
  init(from packetReader: inout PacketReader) throws {
//    let chunkX = packetReader.readInt()
//    let chunkZ = packetReader.readInt()
//    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
//    let chunkData = ChunkData(position: position, data: packetReader.buf)
//    chunk = try chunkData.unpack()
    let bytes = packetReader.buf.byteBuf
    data = Data(bytes)
  }
  
  func handle(for server: Server) {
//    server.currentWorld!.addChunk(data: chunk)
    server.testChunk = data
  }
}
