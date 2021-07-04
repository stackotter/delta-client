//
//  MojangBlockModelTransform.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// Block model transform as read from block model json file in resource packs.
/// Translation is applied before rotation.
public struct MojangBlockModelTransform: Codable {
  /// The rotation (should be `[x, y, z]`).
  public var rotation: [Double]
  /// The translation (should be `[x, y, z]`). Clamp to between -80 and 80.
  public var translation: [Double]
  /// The scale (should be `[x, y, z]`). Maximum 4.
  public var scale: [Double]
  
  /// Returns a transformation matrix representing this transform.
  public func toMatrix() throws -> matrix_float4x4 {
    let rotation = try MathUtil.vectorFloat3(from: self.rotation)
    var translation = try MathUtil.vectorFloat3(from: self.translation)
    translation = clamp(translation, min: -80, max: 80)
    var scale = try MathUtil.vectorFloat3(from: self.scale)
    scale = clamp(scale, min: -Float.greatestFiniteMagnitude, max: 4)
    
    var matrix = MatrixUtil.translationMatrix(translation)
    matrix *= MatrixUtil.rotationMatrix(x: rotation.x)
    matrix *= MatrixUtil.rotationMatrix(x: rotation.y)
    matrix *= MatrixUtil.rotationMatrix(x: rotation.z)
    matrix *= MatrixUtil.scalingMatrix(scale)
    
    return matrix
  }
}
