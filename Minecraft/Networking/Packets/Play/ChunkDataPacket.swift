//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: Packet {
  typealias PacketType = ChunkDataPacket
  var id: Int = 0x20
  
  static func from(_ packetReader: PacketReader) -> ChunkDataPacket? {
    // TODO: implement
    return ChunkDataPacket()
  }
}
