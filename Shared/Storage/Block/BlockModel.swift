//
//  BlockModel.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

/// A descriptor for how to render a specific block.
public struct BlockModel {
  /// Directions that this block model can cull other blocks' faces in.
  public var cullingFaces: Set<Direction>
  /// Whether to use ambient occlusion or not.
  public var ambientOcclusion: Bool
  /// Index of the transforms to use when displaying this block.
  public var displayTransformsIndex: Int?
  /// The elements that make up this block model.
  public var elements: [BlockModelElement]
}
