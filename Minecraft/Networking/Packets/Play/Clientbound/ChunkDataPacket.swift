//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: Packet {
  typealias PacketType = ChunkDataPacket
  static let id: Int = 0x21
  
  var chunk: Chunk
  
  init(fromReader packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    let chunkData = ChunkData(position: position, data: packetReader.buf)
    chunk = try chunkData.unpack()
  }
}
