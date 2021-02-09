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
  var chunks: [ChunkPosition: Chunk] = [:]
  var eventManager: EventManager
  var config: WorldConfig
  
  init(eventManager: EventManager, config: WorldConfig) {
    self.eventManager = eventManager
    self.config = config
  }
  
  func addChunk(data chunk: Chunk) {
    chunks[chunk.position] = chunk
  }
}
