//
//  World.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

// NOTE: might need to be made threadsafe?
class World {
  var packedChunks: [ChunkPosition: ChunkData] = [:] // chunks that haven't been unpacked yet
  var chunks: [ChunkPosition: Chunk] = [:]
  var config: WorldConfig
  var age: Int64 = -1
  
  var downloadingTerrain: Bool = true
  
  var chunkThread: DispatchQueue = DispatchQueue(label: "worldChunks")
  var managers: Managers
  
  init(config: WorldConfig, managers: Managers) {
    self.config = config
    self.managers = managers
  }
  
  func setBlock(at position: Position, to state: UInt16) {
    if chunks[position.chunkPosition] != nil {
      chunks[position.chunkPosition]!.setBlock(at: position.relativeToChunk, to: state)
    } else {
      Logger.log("attempt to update block in non-existent chunk at \(position.chunkPosition)")
    }
  }
  
  func getBlock(at position: Position) -> UInt16 {
    if let chunk = chunks[position.chunkPosition] {
      return chunk.getBlock(at: position.relativeToChunk)
    } else {
      Logger.log("no chunk at \(position.chunkPosition)")
      chunks.forEach {
        print($0.key)
      }
      return 0 // air
    }
  }
  
  func addChunk(_ chunk: Chunk) {
    chunks[chunk.position] = chunk
  }
  
  func addChunkData(_ chunkData: ChunkData, unpack: Bool) {
    if unpack {
      chunkThread.async {
        do {
          let chunk = try chunkData.unpack()
          self.addChunk(chunk)
          self.packedChunks.removeValue(forKey: chunk.position)
          if self.packedChunks.count == 0 {
            self.downloadingTerrain = false
            self.managers.eventManager.triggerEvent(.downloadedTerrain)
          }
        } catch {
          Logger.log("failed to unpack chunk at (\(chunkData.position.chunkX), \(chunkData.position.chunkZ))")
        }
      }
    } else {
      packedChunks[chunkData.position] = chunkData
    }
  }
  
  func removeChunk(at position: ChunkPosition) {
    self.chunks.removeValue(forKey: position)
    self.packedChunks.removeValue(forKey: position)
  }
  
  func unpackChunks() throws {
    for packedChunk in packedChunks.values {
      addChunkData(packedChunk, unpack: true)
    }
  }
}
