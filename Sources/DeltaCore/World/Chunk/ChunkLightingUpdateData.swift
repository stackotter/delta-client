//
//  ChunkLightingUpdateData.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/6/21.
//

import Foundation

// TODO: just use the packet instead of this thing
public struct ChunkLightingUpdateData {
  public var trustEdges: Bool
  public var emptySkyLightSections: [Int]
  public var emptyBlockLightSections: [Int]
  public var skyLightArrays: [Int: [UInt8]]
  public var blockLightArrays: [Int: [UInt8]]
}
