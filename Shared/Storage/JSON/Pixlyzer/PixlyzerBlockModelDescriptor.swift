//
//  PixlyzerBlockModelDescriptor.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

public struct PixlyzerBlockModelDescriptor: Codable {
  var model: Identifier
  var xRotation: Int?
  var yRotation: Int?
  var uvLock: Bool?
  
  enum CodingKeys: String, CodingKey {
    case model
    case xRotation = "x"
    case yRotation = "y"
    case uvLock = "uvlock"
  }
  
  var rotationMatrix: matrix_float4x4 {
    // Create a vector for the rotation
    let rotation = simd_float3(
      Float(xRotation ?? 0),
      Float(yRotation ?? 0),
      0)
    
    // Apply the rotation, rotating around the center of the block
    let origin = simd_float3(repeating: 0.5)
    let matrix = MatrixUtil.translationMatrix(-origin)
      * MatrixUtil.rotationMatrix(rotation)
      * MatrixUtil.translationMatrix(origin)
    
    return matrix
  }
}
