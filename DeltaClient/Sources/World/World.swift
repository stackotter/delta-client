//
//  World.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation


// TODO: make World threadsafe
class World {
  var config: WorldConfig
  var age: Int = -1
  
  var downloadingTerrain: Bool = true
  var chunks: [ChunkPosition: Chunk] = [:]
  var lighting: [ChunkPosition: ChunkLighting] = [:]
  
  var chunkThread = DispatchQueue(label: "worldChunks")
  var managers: Managers
  var eventManager: EventManager<ServerEvent>
  
  init(config: WorldConfig, managers: Managers, eventManager: EventManager<ServerEvent>) {
    self.config = config
    self.managers = managers
    self.eventManager = eventManager
  }
  
  // Block
  
  func setBlock(at position: Position, to state: UInt16) {
    if let chunk = chunks[position.chunkPosition] {
      chunk.setBlock(at: position.relativeToChunk, to: state)
    } else {
      Logger.warn("attempt to update block in non-existent chunk at \(position.chunkPosition)")
    }
  }
  
  func getBlock(at position: Position) -> UInt16 {
    if let chunk = chunks[position.chunkPosition] {
      return chunk.getBlock(at: position.relativeToChunk)
    } else {
      Logger.warn("get block called for non existent chunk: \(position.chunkPosition)")
      return 0 // air
    }
  }
  
  // Chunk
  
  func getIsChunkReady(_ position: ChunkPosition) -> Bool {
    return chunks[position] != nil && lighting[position] != nil
  }
  
  func finishDownloadingTerrain() {
    // wait until last chunk is unpacked
    chunkThread.sync {
      downloadingTerrain = false
      DeltaClientApp.eventManager.triggerEvent(.downloadedTerrain)
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
  
  func addChunkData(_ chunkData: ChunkData) {
    chunkThread.async {
      do {
        let chunk = try chunkData.unpack(blockPaletteManager: self.managers.blockPaletteManager)
        self.addChunk(chunk)
      } catch {
        Logger.error("failed to unpack chunk at (\(chunkData.position.chunkX), \(chunkData.position.chunkZ))")
      }
    }
  }
  
  func removeChunk(at position: ChunkPosition) {
    self.chunks.removeValue(forKey: position)
  }
}
