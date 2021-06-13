//
//  UnpackedChunkData.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/6/21.
//

import Foundation

struct UnpackedChunkData {
  var chunkPosition: ChunkPosition
  var fullChunk: Bool
  var primaryBitMask: Int
  var heightMaps: NBTCompound
  var ignoreOldData: Bool
  var biomes: [UInt8]
  var sections: [Chunk.Section]
  var blockEntities: [BlockEntity]
  
  var presentSections: [Int] {
    return BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
  }
}
