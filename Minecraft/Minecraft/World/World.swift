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
  var config: WorldConfig
  var age: Int64 = -1
  
  init(config: WorldConfig) {
    self.config = config
  }
  
  func addChunk(data chunk: Chunk) {
    chunks[chunk.position] = chunk
  }
}
