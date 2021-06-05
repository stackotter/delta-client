//
//  ChunkLighting.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 17/4/21.
//

import Foundation

class ChunkLighting {
  static var DEFAULT_SKYLIGHT_LEVEL: UInt8 = 255
  static var DEFAULT_BLOCKLIGHT_LEVEL: UInt8 = 255
  
  var skyLightData: [Int: [UInt8]] = [:]
  var blockLightData: [Int: [UInt8]] = [:]
  
  func updateSectionBlockLight(with data: [UInt8], for sectionIndex: Int) {
    blockLightData[sectionIndex] = data
  }
  
  func updateSectionSkyLight(with data: [UInt8], for sectionIndex: Int) {
    skyLightData[sectionIndex] = data
  }
  
  func getSkyLightLevel(at position: Position) -> UInt8 {
    let index = position.relativeToChunkSection.blockIndex
    if let skyLightArray = skyLightData[position.sectionIndex] {
      let compactValue = skyLightArray[index >> 1]
      let level: UInt8
      if index & 0x1 == 0x0 { // even
        level = compactValue & 0xf
      } else { // odd
        level = compactValue >> 4
      }
      return level
    } else {
      return ChunkLighting.DEFAULT_SKYLIGHT_LEVEL
    }
  }
  
  func getBlockLightLevel(at position: Position) -> UInt8 {
    let index = position.relativeToChunkSection.blockIndex
    if let blockLightArray = blockLightData[position.sectionIndex] {
      let compactValue = blockLightArray[index >> 1]
      let level: UInt8
      if index & 0x1 == 0x0 { // even
        level = compactValue & 0xf
      } else { // odd
        level = compactValue >> 4
      }
      return level
    } else {
      return ChunkLighting.DEFAULT_BLOCKLIGHT_LEVEL
    }
  }
}
