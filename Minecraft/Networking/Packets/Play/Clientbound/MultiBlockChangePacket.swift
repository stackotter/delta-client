//
//  MultiBlockChangePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct MultiBlockChangePacket: ClientboundPacket {
  static let id: Int = 0x0f
  
  struct BlockChangeRecord {
    // position relative to the chunk
    var x: UInt8
    var y: UInt8
    var z: UInt8
    
    var blockId: Int
  }
  
  var chunkPosition: ChunkPosition
  var records: [BlockChangeRecord]
  
  init(from packetReader: inout PacketReader) throws {
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    
    records = []
    
    let recordCount = packetReader.readVarInt()
    for _ in 0..<recordCount {
      let val = packetReader.readUnsignedByte()
      let x = val >> 4
      let z = val & 0x0f
      let y = packetReader.readUnsignedByte()
      let blockId = packetReader.readVarInt()
      let record = BlockChangeRecord(x: x, y: y, z: z, blockId: blockId)
      records.append(record)
    }
  }
}
