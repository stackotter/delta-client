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
    
    var blockId: Int32
  }
  
  var chunkPosition: ChunkPosition
  var records: [BlockChangeRecord]
  
  init(fromReader packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
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
