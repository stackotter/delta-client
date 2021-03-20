//
//  Chunk.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import os

class Chunk {
  var position: ChunkPosition
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var blockEntities: [BlockEntity]
  var sections: [ChunkSection]
  
  var neighbours: [CardinalDirection: Chunk] = [:]
  
  var mesh: ChunkMesh
  
  // private because it shouldn't be used directly cause of its weird storage format
  private var biomes: [UInt8]
  
  init(position: ChunkPosition, heightMaps: NBTCompound, ignoreOldData: Bool, biomes: [UInt8], sections: [ChunkSection], blockEntities: [BlockEntity]) {
    self.position = position
    self.heightMaps = heightMaps
    self.ignoreOldData = ignoreOldData
    self.biomes = biomes
    self.sections = sections
    self.blockEntities = blockEntities
    
    self.mesh = ChunkMesh()
  }
  
  func setNeighbour(to chunk: Chunk, direction: CardinalDirection) {
    neighbours[direction] = chunk
  }
  
  func generateMesh(with blockModelManager: BlockModelManager) {
    self.mesh.ingestChunk(chunk: self, blockModelManager: blockModelManager)
  }
  
  // TODO_LATER: calculate the index in the function
  func getBiome(index: Int) -> UInt8 {
    // because of the efficient way they were read in chunkdata only every fourth value is a biome id
    // they get sent as int32 but they are never take up more than a byte
    return biomes[index*4+3]
  }
  
  func getRelativeY(y: Int, sectionNum: Int) -> Int {
    return y - sectionNum*16
  }
  
  // position must be relative to chunk
  func getBlock(at position: Position) -> UInt16 {
    return getBlock(atX: Int(position.x), y: Int(position.y), andZ: Int(position.z))
  }
  
  // TODO: clean up use of integer types
  func getBlock(atX x: Int, y: Int, andZ z: Int) -> UInt16 {
    let sectionNum = y / 16 // divides by 16 and rounds down
    let sectionY = getRelativeY(y: y, sectionNum: sectionNum)
    return sections[sectionNum].getBlockId(atX: Int32(x), y: Int32(sectionY), andZ: Int32(z))
  }
  
  func getBlock(atIndex index: Int) -> UInt16 {
    let sectionNum = index / 4096
    let state = sections[sectionNum].blocks[index - (sectionNum * 4096)]
    return state
  }
  
  // TODO: get rid of these double functions, decide on one (after choosing int type to use)
  func setBlock(at position: Position, to newState: UInt16) {
    setBlock(atX: Int(position.x), y: Int(position.y), andZ: Int(position.z), to: newState)
  }
  
  func setBlock(atX x: Int, y: Int, andZ z: Int, to newState: UInt16) {
//    let sectionNum = y / 16
//    let sectionY = getRelativeY(y: y, sectionNum: sectionNum)
//    let currentState = getBlock(atX: x, y: y, andZ: z)
//    let blockIndex = ChunkSection.blockIndexFrom(x, y, z)
//    if currentState == newState {
//      Logger.debug("doing nothing, state not changing")
//      return
//    }
//    if currentState != 0 {
//      Logger.debug("current block is not air, removing")
//      mesh.removeBlock(atIndex: blockIndex) // TODO: implement replace block
//    }
//    if newState != 0 {
//      Logger.debug("new block is not air, adding")
//      mesh.addBlock(x, y, z, index: blockIndex, faces: Set<Direction>([.up, .down, .east, .west, .north, .south]))
//    }
//    Logger.debug("setting block in chunk section")
//    sections[sectionNum].setBlockId(atX: Int32(x), y: Int32(sectionY), andZ: Int32(z), to: newState)
  }
  
  // index is (y*16 + z)*16 + x
  func getPresentNeighbours(forIndex index: Int) -> Set<FaceDirection> {
    var presentNeighbours: Set<FaceDirection> = Set<FaceDirection>()
    
    let currentRow = Int((Float(index) / 16.0).rounded(.down))
    let currentLayer = Int((Float(index) / 256.0).rounded(.down))
    
    let westBlockIndex = index - 1
    let eastBlockIndex = index + 1
    
    let northBlockIndex = index - 16
    let southBlockIndex = index + 16
    
    let downBlockIndex = index - 256
    let upBlockIndex = index + 256
    
    if Int((Float(westBlockIndex) / 16.0).rounded(.down)) == currentRow {
      if getBlock(atIndex: westBlockIndex) != 0 {
        presentNeighbours.insert(.west)
      }
    } else if let westChunk = neighbours[.west] {
      if westChunk.getBlock(atIndex: index + 15) != 0 {
        presentNeighbours.insert(.west)
      }
    }
    
    if Int((Float(eastBlockIndex) / 16.0).rounded(.down)) == currentRow {
      if getBlock(atIndex: eastBlockIndex) != 0 {
        presentNeighbours.insert(.east)
      }
    } else if let eastChunk = neighbours[.west] {
      if eastChunk.getBlock(atIndex: index - 15) != 0 {
        presentNeighbours.insert(.east)
      }
    }
    
    if northBlockIndex >= currentLayer*256 {
      if getBlock(atIndex: northBlockIndex) != 0 {
        presentNeighbours.insert(.north)
      }
    } else if let northChunk = neighbours[.north] {
      if northChunk.getBlock(atIndex: index + (15*16)) != 0 {
        presentNeighbours.insert(.north)
      }
    }
    
    if southBlockIndex < (currentLayer+1)*256 {
      if getBlock(atIndex: southBlockIndex) != 0 {
        presentNeighbours.insert(.south)
      }
    } else if let southChunk = neighbours[.south] {
      if southChunk.getBlock(atIndex: index - (15*16)) != 0 {
        presentNeighbours.insert(.south)
      }
    }
    
    if downBlockIndex >= 0 {
      if getBlock(atIndex: downBlockIndex) != 0 {
        presentNeighbours.insert(.down)
      }
    }
    
    if upBlockIndex < 16*16*256 {
      if getBlock(atIndex: upBlockIndex) != 0 {
        presentNeighbours.insert(.up)
      }
    }
    
    return presentNeighbours
  }
}
