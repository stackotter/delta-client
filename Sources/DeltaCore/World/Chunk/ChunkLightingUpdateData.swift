//
//  ChunkLightingUpdateData.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/6/21.
//

import Foundation

struct ChunkLightingUpdateData {
  var trustEdges: Bool
  var skyLightMask: Int
  var blockLightMask: Int
  var emptySkyLightMask: Int
  var emptyBlockLightMask: Int
  var skyLightArrays: [[UInt8]]
  var blockLightArrays: [[UInt8]]
}
