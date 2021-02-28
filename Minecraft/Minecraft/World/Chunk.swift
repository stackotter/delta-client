//
//  Chunk.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct Chunk {
  var position: ChunkPosition
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var sections: [ChunkSection]
  var blockEntities: [BlockEntity]
  
  // private because it shouldn't be used directly cause of its weird storage format
  private var biomes: [UInt8]
  
  init(position: ChunkPosition, heightMaps: NBTCompound, ignoreOldData: Bool, biomes: [UInt8], sections: [ChunkSection], blockEntities: [BlockEntity]) {
    self.position = position
    self.heightMaps = heightMaps
    self.ignoreOldData = ignoreOldData
    self.biomes = biomes
    self.sections = sections
    self.blockEntities = blockEntities
  }
  
  // TODO_LATER: calculate the index in the function
  func getBiome(index: Int) -> UInt8 {
    // because of the efficient way they were read in chunkdata only every fourth value is a biome id
    // they get sent as int32 but they are never take up more than a byte
    return biomes[index*4+3]
  }
  
  // position must be relative to chunk
  func getBlock(at position: Position) -> UInt16 {
    let sectionNum = position.y >> 4 // divides by 16 and rounds down
    let sectionY = position.y - sectionNum*16
    return sections[Int(sectionNum)].getBlockId(atX: position.x, y: sectionY, andZ: position.z)
  }
  
  mutating func setBlock(at position: Position, to state: UInt16) {
    let sectionNum = position.y >> 4
    let sectionY = position.y - sectionNum*16
    sections[Int(sectionNum)].setBlockId(atX: position.x, y: sectionY, andZ: position.z, to: state)
  }
}
