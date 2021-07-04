//
//  FlatMojangBlockModel.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

/// Flattened mojang block model format.
public struct FlatMojangBlockModel {
  /// Whether to use ambient occlusion or not.
  public var ambientOcclusion: Bool
  /// Index of the transforms to use when displaying this block.
  public var displayTransformsIndex: Int?
  /// The elements that make up this block model.
  public var elements: [FlatMojangBlockModelElement]
}
