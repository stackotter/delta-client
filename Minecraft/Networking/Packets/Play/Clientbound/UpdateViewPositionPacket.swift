//
//  UpdateViewPositionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

struct UpdateViewPositionPacket: Packet {
  typealias PacketType = UpdateViewPositionPacket
  static let id: Int = 0x40
  
  var chunkPosition: ChunkPosition
  
  // TODO: use inout to avoid the whole mutable reader business
  static func from(_ packetReader: PacketReader) -> UpdateViewPositionPacket? {
    var mutableReader = packetReader
    let chunkX = mutableReader.readVarInt()
    let chunkZ = mutableReader.readVarInt()
    return UpdateViewPositionPacket(chunkPosition: ChunkPosition(chunkX: chunkX, chunkZ: chunkZ))
  }
}
