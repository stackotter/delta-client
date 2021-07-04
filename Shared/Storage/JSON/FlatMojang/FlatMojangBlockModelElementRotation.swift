//
//  FlatMojangBlockModelElementRotation.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// A neatened format for `MojangBlockModelElementRotation`.
public struct FlatMojangBlockModelElementRotation {
  /// The point to rotate around.
  var origin: simd_float3
  /// The axis of the rotation.
  var axis: Axis
  /// The angle of the rotation in degrees.
  var degrees: Float
  /// Whether to scale block to fit original space after rotation or not, if nil assume false.
  var rescale: Bool
  
  /// Converts a mojang formatted rotation to this nicer format.
  init(from mojangRotation: MojangBlockModelElementRotation) throws {
    origin = try MathUtil.vectorFloat3(from: mojangRotation.origin)
    axis = mojangRotation.axis.axis
    rescale = mojangRotation.rescale ?? false
    
    // Clamp angle to between -45 and 45 then round to nearest 22.5
    degrees = min(max(-45, Float(mojangRotation.angle)), 45)
    degrees = degrees - (degrees.truncatingRemainder(dividingBy: 22.5))
  }
  
  /// Returns a transformation matrix representing this rotation. Rescale is not implemented.
  var matrix: matrix_float4x4 {
    let radians = MathUtil.radians(from: degrees)
    var matrix = MatrixUtil.translationMatrix(-origin)
    matrix *= MatrixUtil.rotationMatrix(radians, around: axis)
    matrix *= MatrixUtil.translationMatrix(origin)
    // TODO: rescale
    return matrix
  }
}
