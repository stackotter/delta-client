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
  // holds chunk data that is yet to be unpacked
  var packedChunks: [ChunkPosition: ChunkData] = [:]
  
  // holds unpacked chunks
  var chunks: [ChunkPosition: Chunk] = [:]
  
  var logger: Logger
  var eventManager: EventManager
  
  var config: WorldConfig
  
  init(eventManager: EventManager, config: WorldConfig) {
    self.eventManager = eventManager
    self.logger = Logger(for: type(of: self))
    self.config = config
  }
  
  func addChunk(data chunkData: ChunkData) {
    if packedChunks[chunkData.position] != nil {
      logger.debug("duplicate chunk received")
    }
    packedChunks[chunkData.position] = chunkData
  }
  
  // unpacks chunks within a square around the specified chunk
  // radius is currently used to construct a square around the player, could go for a circle in future
  func unpackChunks(aroundChunk centreChunkPos: ChunkPosition, withRadius radius: Int32) {
    // will contain chunks ordered by distance from player
    let orderedChunks = packedChunks.values.sorted(by: {
      squareDistBetweenChunks(centreChunkPos, $0.position) < squareDistBetweenChunks(centreChunkPos, $1.position)
    })
    
    for chunk in orderedChunks {
      print("chunkhi: \(chunk.position)")
    }
  }
  
  // can usually be used in place of distance to reduce number of sqrt operations
  func squareDistBetweenChunks(_ firstChunkPos: ChunkPosition, _ secondChunkPos: ChunkPosition) -> Int32 {
    let distX = firstChunkPos.chunkX - secondChunkPos.chunkX
    let distZ = firstChunkPos.chunkZ - secondChunkPos.chunkZ
    let distanceSquared = distX*distX + distZ*distZ
    return distanceSquared
  }
}
