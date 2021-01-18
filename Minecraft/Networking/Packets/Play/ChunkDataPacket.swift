//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: Packet {
  typealias PacketType = ChunkDataPacket
  static let id: Int = 0x20
  
  var chunkData: ChunkData
  
  static func from(_ packetReader: PacketReader) -> ChunkDataPacket? {
    var mutableReader = packetReader
    let chunkX = mutableReader.readInt()
    let chunkZ = mutableReader.readInt()
    let position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    let chunkData = ChunkData(position: position, data: mutableReader.buf)
    return ChunkDataPacket(chunkData: chunkData)
  }
}
