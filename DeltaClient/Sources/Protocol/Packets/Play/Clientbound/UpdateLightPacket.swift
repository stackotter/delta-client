//
//  UpdateLightPacket.swift
//  DeltaClient
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
    var numArrays = BinaryUtil.setBits(of: skyLightMask, n: Chunk.numSections).count
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      skyLightArrays.append(bytes)
    }
    
    blockLightArrays = []
    numArrays = BinaryUtil.setBits(of: blockLightMask, n: Chunk.numSections).count
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      blockLightArrays.append(bytes)
    }
  }
  
  func handle(for server: Server) throws {
    if let world = server.world {
      let data = ChunkLightingUpdateData(
        trustEdges: trustEdges,
        skyLightMask: skyLightMask,
        blockLightMask: blockLightMask,
        emptySkyLightMask: emptySkyLightMask,
        emptyBlockLightMask: emptyBlockLightMask,
        skyLightArrays: skyLightArrays,
        blockLightArrays: blockLightArrays)
      world.updateChunkLighting(at: chunkPosition, with: data)
    }
  }
}
