//
//  Chunk.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation


class Chunk {
  // constants
  static let WIDTH = 16
  static let DEPTH = 16
  static let HEIGHT = 256
  static let BLOCKS_PER_LAYER = WIDTH * DEPTH
  static let NUM_BLOCKS = HEIGHT * BLOCKS_PER_LAYER
  static let NUM_SECTIONS = 16
  
  // chunk data
  var position: ChunkPosition
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var blockEntities: [BlockEntity]
  var sections: [ChunkSection]
  
  // neighbour chunks
  var neighbours: [CardinalDirection: Chunk] = [:]
  var hasAllNeighbours: Bool {
    return neighbours.count == 4
  }
  
  var blockPaletteManager: BlockPaletteManager
  var mesh: ChunkMesh!
  
  var stopwatch = Stopwatch(mode: .summary, name: "chunk")
  
  // in the format that it is received
  var biomes: [UInt8]
  
  init(position: ChunkPosition, heightMaps: NBTCompound, ignoreOldData: Bool, biomes: [UInt8], sections: [ChunkSection], blockEntities: [BlockEntity], blockPaletteManager: BlockPaletteManager) {
    self.position = position
    self.heightMaps = heightMaps
    self.ignoreOldData = ignoreOldData
    self.biomes = biomes
    self.sections = sections
    self.blockEntities = blockEntities
    
    self.blockPaletteManager = blockPaletteManager
    self.mesh = ChunkMesh(blockPaletteManager: blockPaletteManager, chunk: self)
  }
  
  func setNeighbour(to chunk: Chunk, direction: CardinalDirection) {
    neighbours[direction] = chunk
  }
  
  func generateMesh() {
    self.mesh.ingestChunk()
  }
  
  // TODO_LATER: calculate the index in the function
  func getBiome(index: Int) -> UInt8 {
    // because of the efficient way they were read in chunkdata only every fourth value is a biome id
    // they get sent as int32 but they are never take up more than a byte
    return biomes[index * 4 + 3]
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
    if position.y >= 0 && position.y < 256 {
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
    } else {
      Logger.warn("block change at y=\(position.y) (ignored)")
    }
  }
  
  func getNeighbouringBlocks(forIndex index: Int) -> [FaceDirection: (Chunk, Int)] {
    var neighbouringBlocks: [FaceDirection: (Chunk, Int)] = [:]
    
    // using c to generate the relevant indices (saved about 25ms out of 100ms when implemented)
    let resultTuple = get_neighbouring_blocks(index).neighbours
    
    // convert the tuple returned into an array
    let result = [
      resultTuple.0,
      resultTuple.1,
      resultTuple.2,
      resultTuple.3,
      resultTuple.4,
      resultTuple.5
    ]
    
    // convert the c function's return value into a more useful format
    let chunks = [self, neighbours[.north], neighbours[.east], neighbours[.south], neighbours[.west]]
    for (index, neighbour) in result.enumerated() {
      if neighbour.chunk_num != -1, let neighbourChunk = chunks[neighbour.chunk_num] {
        if let direction = FaceDirection(rawValue: index) {
          neighbouringBlocks[direction] = (neighbourChunk, neighbour.index)
        }
      }
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
  
  func getCullingNeighbours(forIndex index: Int, x: Int, y: Int, z: Int) -> [FaceDirection] {
    let neighbouringBlocks = getNeighbouringBlocks(forIndex: index)
    
    var cullingNeighbours: [FaceDirection] = []
    for (direction, (chunk, index)) in neighbouringBlocks {
      let state = chunk.getBlock(atIndex: index)
      if state != 0 {
        if let blockModel = blockPaletteManager.getVariant(for: state, x: x, y: y, z: z) {
          if blockModel.fullFaces.contains(direction.opposite) {
            cullingNeighbours.append(direction)
          }
        }
      }
    }
    
    return cullingNeighbours
  }
  
  func getAABB() -> AxisAlignedBoundingBox {
    AxisAlignedBoundingBox(forChunk: self)
  }
}
