//
//  IntermediateBlockModelElementRotation.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import simd

/// A neatened format for `JSONBlockModelElementRotation`.
public struct IntermediateBlockModelElementRotation {
  /// The point to rotate around.
  var origin: simd_float3
  /// The axis of the rotation.
  var axis: Axis
  /// The angle of the rotation in radians.
  var radians: Float
  /// Whether to scale block to fit original space after rotation or not.
  var rescale: Bool
  
  /// Converts a mojang formatted rotation to this nicer format.
  init(from mojangRotation: JSONBlockModelElementRotation) throws {
    origin = try MathUtil.vectorFloat3(from: mojangRotation.origin) / 16
    axis = mojangRotation.axis.axis
    rescale = mojangRotation.rescale ?? false
    
    // Clamp angle to between -45 and 45 then round to nearest 22.5
    var degrees = min(max(-45, Float(mojangRotation.angle)), 45)
    degrees = degrees - (degrees.truncatingRemainder(dividingBy: 22.5))
    radians = MathUtil.radians(from: Float(degrees))
    
    // For some reason in our renderer we need x rotation to be reversed but only
    // for rotations from mojang block model files everything else is fine?
    switch axis {
      case .x:
        radians = -radians
      case .y, .z:
        break
    }
  }
  
  /// Returns a transformation matrix representing this rotation. Rescale is not implemented.
  var matrix: matrix_float4x4 {
    var matrix = MatrixUtil.translationMatrix(-origin)
    matrix *= MatrixUtil.rotationMatrix(radians, around: axis)
    matrix *= MatrixUtil.translationMatrix(origin)
    // TODO: rescale
    return matrix
  }
}
