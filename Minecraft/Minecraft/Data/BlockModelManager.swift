//
//  BlockModelManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import simd
import os

enum BlockModelError: LocalizedError {
  case invalidPixlyzerData
}

enum FaceDirection: String {
  case down = "down"
  case up = "up"
  case north = "north"
  case south = "south"
  case west = "west"
  case east = "east"
}

// an intermediate block model used before global palette is loaded
struct IntermediateBlockModelElementFace {
  var textureCoordinates: (simd_float2, simd_float2)
  var textureVariable: String
  var cullface: FaceDirection?
  var rotation: Int
  var tintIndex: Int?
}

struct IntermediateBlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: IntermediateBlockModelElementFace]
}

struct IntermediateBlockModel {
  var elements: [IntermediateBlockModelElement]
}

// the actual block model structure used for rendering
struct BlockModelElementFace {
  var textureCoordinates: (simd_float2, simd_float2)
  var textureIndex: Int // the index of the texture to use in the block texture buffer
  var cullface: FaceDirection?
  var tintIndex: Int?
}

struct BlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: BlockModelElementFace]
}

struct BlockModel {
  var elements: [BlockModelElement]
}


// TODO: think of a better name for BlockModelManager
class BlockModelManager {
  var assetManager: AssetManager
  var textureManager: TextureManager
  
  var blockModelPalette: [Int: BlockModel] = [:]
  
  init(assetManager: AssetManager, textureManager: TextureManager) {
    self.assetManager = assetManager
    self.textureManager = textureManager
  }
  
  func loadGlobalPalette() throws {
    let pixlyzerDataFile = assetManager.getPixlyzerFolder()!.appendingPathComponent("blocks.json")
    guard let pixlyzerJSON = try? JSON.fromURL(pixlyzerDataFile).dict as? [String: [String: Any]] else {
      Logger.error("failed to parse pixlyzer block palette")
      throw BlockModelError.invalidPixlyzerData
    }
    for (blockName, block) in pixlyzerJSON {
      guard let states = JSON(dict: block).getJSON(forKey: "states")?.dict as? [String: [String: Any]] else {
        Logger.error("invalid pixlyzer json format")
        throw BlockModelError.invalidPixlyzerData
      }
      for (stateIdString, state) in states {
        Logger.debug(stateIdString)
      }
    }
  }
}
