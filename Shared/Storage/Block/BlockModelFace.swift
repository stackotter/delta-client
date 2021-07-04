//
//  BlockModelFace.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// A descriptor for a block model element's face
public struct BlockModelFace {
  /// The direction the face should face before transformations are applied.
  /// This won't always be the direction the face ends up facing.
  var direction: Direction
  /// Face texture uv coordinates (if they're not present we have to make them up).
  var uv: (simd_float2, simd_float2)
  /// The index of the texture to use in the texture palette.
  var texture: Int
  /// The direction that a culling block must be in for this face not to be rendered.
  var cullface: Direction?
  /// The normal of this face.
  var normal: simd_float3
  /// The index of the tint to use.
  var tintIndex: Int
}
