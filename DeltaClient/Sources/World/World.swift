//
//  World.swift
//  DeltaClient
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
  var age: Int = -1
  
  var downloadingTerrain: Bool = true
  
  var chunkThread: DispatchQueue = DispatchQueue(label: "worldChunks")
  var managers: Managers
  
  init(config: WorldConfig, managers: Managers) {
    self.config = config
    self.managers = managers
  }
  
  func setBlock(at position: Position, to state: UInt16) {
    if let chunk = chunks[position.chunkPosition] {
      chunk.setBlock(at: position.relativeToChunk, to: state)
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
    // set chunk's neighbours
    var eastCoordinate = chunk.position
    eastCoordinate.chunkX += 1
    var westCoordinate = chunk.position
    westCoordinate.chunkX -= 1
    
    var southCoordinate = chunk.position
    southCoordinate.chunkZ += 1
    var northCoordinate = chunk.position
    northCoordinate.chunkZ -= 1
    
    let neighbourCoordinates: [CardinalDirection: ChunkPosition] = [
      .north: northCoordinate,
      .east: eastCoordinate,
      .south: southCoordinate,
      .west: westCoordinate
    ]
    
    for (direction, coordinate) in neighbourCoordinates {
      if let neighbour = chunks[coordinate] {
        chunk.setNeighbour(to: neighbour, direction: direction)
        neighbour.setNeighbour(to: chunk, direction: direction.opposite)
      }
    }
    
    // add chunk
    chunks[chunk.position] = chunk
  }
  
  func addChunkData(_ chunkData: ChunkData, unpack: Bool) {
    if unpack {
      chunkThread.async {
        do {
          let chunk = try chunkData.unpack(blockPaletteManager: self.managers.blockPaletteManager)
          self.addChunk(chunk)
          self.packedChunks.removeValue(forKey: chunk.position)
          if self.packedChunks.count == 0 {
            self.downloadingTerrain = false
            self.managers.eventManager.triggerEvent(.downloadedTerrain)
          }
        } catch {
          Logger.error("failed to unpack chunk at (\(chunkData.position.chunkX), \(chunkData.position.chunkZ))")
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
