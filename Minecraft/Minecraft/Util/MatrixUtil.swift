//
//  MatrixUtil.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import simd

struct MatrixUtil {
  static func translationMatrix(_ translation: simd_float3) -> matrix_float4x4 {
    var matrix = matrix_float4x4(1)
    matrix.columns.0 = [1, 0, 0, translation.x]
    matrix.columns.1 = [0, 1, 0, translation.y]
    matrix.columns.2 = [0, 0, 1, translation.z]
    return matrix
  }
  
  static func scalingMatrix(_ factor: Float) -> matrix_float4x4 {
    return scalingMatrix(x: factor, y: factor, z: factor)
  }
  
  static func scalingMatrix(x: Float, y: Float, z: Float) -> matrix_float4x4 {
    return matrix_float4x4(diagonal: [x, y, z, 1])
  }
  
  static func projectionMatrix(near: Float, far: Float, aspect: Float, fieldOfViewY: Float) -> matrix_float4x4 {
    let scaleY = 1 / tan(fieldOfViewY * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -(far + near) / (far - near)
    let scaleW = -2 * far * near / (far - near)
    return matrix_float4x4(columns: (
      simd_float4([scaleX, 0, 0, 0]),
      simd_float4([0, scaleY, 0, 0]),
      simd_float4([0, 0, scaleZ, scaleW]),
      simd_float4([0, 0, -1, 0])
    ))
  }
  
  static func rotationMatrix(x: Float) -> matrix_float4x4 {
    var matrix = matrix_float4x4(1)
    matrix.columns.1 = [
      0,
      cos(x),
      sin(x),
      0
    ]
    
    matrix.columns.2 = [
      0,
      -sin(x),
      cos(x),
      0
    ]
    return matrix
  }
  
  static func rotationMatrix(y: Float) -> matrix_float4x4 {
    var matrix = matrix_float4x4(1)
    matrix.columns.0 = [
      cos(y),
      0,
      -sin(y),
      0
    ]
    
    matrix.columns.2 = [
      sin(y),
      0,
      cos(y),
      0
    ]
    return matrix
  }
  
  static func rotationMatrix(z: Float) -> matrix_float4x4 {
    var matrix = matrix_float4x4(1)
    matrix.columns.0 = [
      cos(z),
      -sin(z),
      0,
      0
    ]
    
    matrix.columns.1 = [
      sin(z),
      cos(z),
      0,
      0
    ]
    return matrix
  }
}
