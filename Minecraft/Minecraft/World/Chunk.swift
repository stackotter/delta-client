//
//  Chunk.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

class Chunk {
  static let WIDTH = 16
  static let DEPTH = 16
  static let HEIGHT = 256
  static let BLOCKS_PER_LAYER = WIDTH * DEPTH
  static let NUM_BLOCKS = HEIGHT * BLOCKS_PER_LAYER
  
  var position: ChunkPosition
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var blockEntities: [BlockEntity]
  var sections: [ChunkSection]
  
  var neighbours: [CardinalDirection: Chunk] = [:]
  
  var blockModelManager: BlockModelManager
  var mesh: ChunkMesh!
  
  // private because it shouldn't be used directly cause of its weird storage format
  private var biomes: [UInt8]
  
  init(position: ChunkPosition, heightMaps: NBTCompound, ignoreOldData: Bool, biomes: [UInt8], sections: [ChunkSection], blockEntities: [BlockEntity], blockModelManager: BlockModelManager) {
    self.position = position
    self.heightMaps = heightMaps
    self.ignoreOldData = ignoreOldData
    self.biomes = biomes
    self.sections = sections
    self.blockEntities = blockEntities
    
    self.blockModelManager = blockModelManager
    self.mesh = ChunkMesh(blockModelManager: blockModelManager, chunk: self)
  }
  
  func setNeighbour(to chunk: Chunk, direction: CardinalDirection) {
    neighbours[direction] = chunk
  }
  
  func generateMesh(with blockModelManager: BlockModelManager) {
    self.mesh.ingestChunk()
  }
  
  // TODO_LATER: calculate the index in the function
  func getBiome(index: Int) -> UInt8 {
    // because of the efficient way they were read in chunkdata only every fourth value is a biome id
    // they get sent as int32 but they are never take up more than a byte
    return biomes[index*4+3]
  }
  
  // position must be relative to chunk
  func getBlock(at position: Position) -> UInt16 {
    let index = blockIndexFrom(Int(position.x), Int(position.y), Int(position.z))
    return getBlock(atIndex: Int(index))
  }
  
  func getBlock(atIndex index: Int) -> UInt16 {
    let sectionNum = index / ChunkSection.NUM_BLOCKS
    let state = sections[sectionNum].blocks[index - (sectionNum * ChunkSection.NUM_BLOCKS)]
    return state
  }
  
  func blockIndexFrom(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return (y * Chunk.DEPTH + z) * Chunk.WIDTH + x
  }
  
  func blockIndexFrom(_ position: Position) -> Int {
    return blockIndexFrom(position.x, position.y, position.z)
  }
  
  func setBlock(at position: Position, to newState: UInt16) {
    let blockIndex = blockIndexFrom(position)
    
    let currentState = getBlock(atIndex: blockIndex)
    if currentState == newState {
      Logger.debug("doing nothing, state not changing")
      return
    }
    
    let sectionNum = Int(position.y / ChunkSection.HEIGHT)
    let sectionIndex = blockIndex - sectionNum * ChunkSection.NUM_BLOCKS
    sections[sectionNum].blocks[sectionIndex] = newState
    
    mesh.replaceBlock(at: blockIndex, newState: newState)
  }
  
  func getNeighbouringBlocks(forIndex index: Int) -> [FaceDirection: (Chunk, Int)] {
    var neighbouringBlocks: [FaceDirection: (Chunk, Int)] = [:]
    
    let currentRow = index / Chunk.WIDTH
    let currentLayer = index / Chunk.BLOCKS_PER_LAYER
    
    let westBlockIndex = index - 1
    let eastBlockIndex = index + 1
    
    let northBlockIndex = index - (Chunk.WIDTH)
    let southBlockIndex = index + (Chunk.WIDTH)
    
    let downBlockIndex = index - Chunk.BLOCKS_PER_LAYER
    let upBlockIndex = index + Chunk.BLOCKS_PER_LAYER
    
    if westBlockIndex >= currentRow * Chunk.WIDTH {
      neighbouringBlocks[.west] = (self, westBlockIndex)
    } else if let westChunk = neighbours[.west] {
      neighbouringBlocks[.west] = (westChunk, index + (Chunk.WIDTH - 1))
    }
    
    if eastBlockIndex <= (currentRow + 1) * Chunk.WIDTH {
      neighbouringBlocks[.east] = (self, eastBlockIndex)
    } else if let eastChunk = neighbours[.west] {
      neighbouringBlocks[.east] = (eastChunk, index - (Chunk.WIDTH - 1))
    }
    
    if northBlockIndex >= currentLayer * Chunk.BLOCKS_PER_LAYER {
      neighbouringBlocks[.north] = (self, northBlockIndex)
    } else if let northChunk = neighbours[.north] {
      neighbouringBlocks[.north] = (northChunk, index + ((Chunk.DEPTH - 1) * Chunk.WIDTH))
    }
    
    if southBlockIndex < (currentLayer+1) * Chunk.BLOCKS_PER_LAYER {
      neighbouringBlocks[.south] = (self, southBlockIndex)
    } else if let southChunk = neighbours[.south] {
      neighbouringBlocks[.south] = (southChunk, index - ((Chunk.DEPTH - 1) * Chunk.WIDTH))
    }
    
    if downBlockIndex >= 0 {
      neighbouringBlocks[.down] = (self, downBlockIndex)
    }
    
    if upBlockIndex < Chunk.NUM_BLOCKS {
      neighbouringBlocks[.up] = (self, upBlockIndex)
    }
    
    return neighbouringBlocks
  }
  
  // get which faces of block are against non-air neighbours
  func getPresentNeighbours(forIndex index: Int) -> [FaceDirection: (Chunk, Int)] {
    var presentNeighbours = getNeighbouringBlocks(forIndex: index)
    
    for (direction, (chunk, index)) in presentNeighbours {
      if chunk.getBlock(atIndex: index) == 0 {
        presentNeighbours.removeValue(forKey: direction)
      }
    }
    
    return presentNeighbours
  }
  
  func getCullingNeighbours(forIndex index: Int) -> [FaceDirection] {
    let presentNeighbours = getNeighbouringBlocks(forIndex: index)
    var cullingNeighbours: [FaceDirection] = []
    
    for (direction, (chunk, index)) in presentNeighbours {
      let state = chunk.getBlock(atIndex: index)
      if state != 0 {
        if let blockModel = blockModelManager.blockModelPalette[state] {
          if blockModel.fullFaces.contains(direction.opposite) {
            cullingNeighbours.append(direction)
          }
        }
      }
    }
    
    return cullingNeighbours
  }
}
