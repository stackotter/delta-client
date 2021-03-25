//
//  UpdateLightPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct UpdateLightPacket: ClientboundPacket {
  static let id: Int = 0x24
  
  var chunkPosition: ChunkPosition
  var trustEdges: Bool
  var skyLightMask: Int
  var blockLightMask: Int
  var emptySkyLightMask: Int
  var emptyBlockLightMask: Int
  var skyLightArrays: [[UInt8]]
  var blockLightArrays: [[UInt8]]
  
  init(from packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readVarInt()
    let chunkZ = packetReader.readVarInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    trustEdges = packetReader.readBool()
    skyLightMask = packetReader.readVarInt()
    blockLightMask = packetReader.readVarInt()
    emptySkyLightMask = packetReader.readVarInt()
    emptyBlockLightMask = packetReader.readVarInt()
    
    skyLightArrays = []
    var numArrays = 0
    for i in 0..<16 {
      numArrays += Int(skyLightMask >> i) & 0x01
    }
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      skyLightArrays.append(bytes)
    }
    
    blockLightArrays = []
    numArrays = 0
    for i in 0..<16 {
      numArrays += Int(blockLightMask >> i) & 0x01
    }
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      blockLightArrays.append(bytes)
    }
  }
}
