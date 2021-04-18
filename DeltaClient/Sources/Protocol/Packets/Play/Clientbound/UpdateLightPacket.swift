//
//  UpdateLightPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation
import os

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
  
  func handle(for server: Server) throws {
    // NOTE: we just ignore the first and last sections sent for now (above and below the world)
    var skyLightIndex = 0
    var blockLightIndex = 0
    if let world = server.world {
      let chunkLighting = world.lighting[chunkPosition] ?? ChunkLighting()
      for i in 0..<(Chunk.NUM_SECTIONS + 1) {
        let sectionNum = i - 1
        if (skyLightMask >> i) & 0x1 == 1 {
          if i == 0 {
            skyLightIndex += 1
            continue
          }
          chunkLighting.updateSectionSkyLight(with: skyLightArrays[skyLightIndex], for: sectionNum)
        } else if (emptySkyLightMask >> i) & 0x1 == 1 {
          // empty sky light section
          chunkLighting.updateSectionSkyLight(with: [UInt8](repeating: 0, count: 2048), for: sectionNum)
        }
        
        if (blockLightMask >> i) & 0x1 == 1 {
          if i == 0 {
            blockLightIndex += 1
            continue
          }
          chunkLighting.updateSectionBlockLight(with: blockLightArrays[blockLightIndex], for: sectionNum)
        } else if (emptyBlockLightMask >> i) & 0x1 == 1 {
          // empty block light section
          chunkLighting.updateSectionBlockLight(with: [UInt8](repeating: 0, count: 2048), for: sectionNum)
        }
      }
      world.lighting[chunkPosition] = chunkLighting
    }
  }
}
