import Foundation
import simd

public enum MatrixUtil {
  public static var identity = matrix_float4x4(1)
  
  public static func translationMatrix(_ translation: SIMD3<Float>) -> matrix_float4x4 {
    var matrix = matrix_float4x4(1)
    matrix.columns.0[3] = translation.x
    matrix.columns.1[3] = translation.y
    matrix.columns.2[3] = translation.z
    return matrix
  }
  
  public static func translationMatrix(_ translation: SIMD3<Double>) -> matrix_double4x4 {
    var matrix = matrix_double4x4(1)
    matrix.columns.0[3] = translation.x
    matrix.columns.1[3] = translation.y
    matrix.columns.2[3] = translation.z
    return matrix
  }
  
  public static func scalingMatrix(_ factor: Float) -> matrix_float4x4 {
    return scalingMatrix(factor, factor, factor)
  }
  
  public static func scalingMatrix(_ factor: Double) -> matrix_double4x4 {
    return scalingMatrix(factor, factor, factor)
  }
  
  public static func scalingMatrix(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
    return scalingMatrix(SIMD3<Float>(x, y, z))
  }
  
  public static func scalingMatrix(_ x: Double, _ y: Double, _ z: Double) -> matrix_double4x4 {
    return scalingMatrix(SIMD3<Double>(x, y, z))
  }
  
  public static func scalingMatrix(_ vector: SIMD3<Float>) -> matrix_float4x4 {
    return matrix_float4x4(diagonal: SIMD4<Float>(vector, 1))
  }
  
  public static func scalingMatrix(_ vector: SIMD3<Double>) -> matrix_double4x4 {
    return matrix_double4x4(diagonal: SIMD4<Double>(vector, 1))
  }
  
  public static func projectionMatrix(near: Float, far: Float, aspect: Float, fieldOfViewY: Float) -> matrix_float4x4 {
    let scaleY = 1 / tan(fieldOfViewY * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -far / (far - near)
    let scaleW = -far * near / (far - near)
    return matrix_float4x4(columns: (
      SIMD4<Float>([scaleX, 0, 0, 0]),
      SIMD4<Float>([0, scaleY, 0, 0]),
      SIMD4<Float>([0, 0, scaleZ, scaleW]),
      SIMD4<Float>([0, 0, -1, 0])
    ))
  }
  
  public static func projectionMatrix(near: Double, far: Double, aspect: Double, fieldOfViewY: Double) -> matrix_double4x4 {
    let scaleY = 1 / tan(fieldOfViewY * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -far / (far - near)
    let scaleW = -far * near / (far - near)
    return matrix_double4x4(columns: (
      SIMD4<Double>([scaleX, 0, 0, 0]),
      SIMD4<Double>([0, scaleY, 0, 0]),
      SIMD4<Double>([0, 0, scaleZ, scaleW]),
      SIMD4<Double>([0, 0, -1, 0])
    ))
  }
  
  /// Returns the rotation matrix applying the rotations in the order of x, then y and then z.
  public static func rotationMatrix(_ rotation: SIMD3<Float>) -> matrix_float4x4 {
    let matrix = rotationMatrix(x: rotation.x)
      * rotationMatrix(y: rotation.y)
      * rotationMatrix(z: rotation.z)
    return matrix
  }
  
  /// Returns the rotation matrix applying the rotations in the order of x, then y and then z.
  public static func rotationMatrix(_ rotation: SIMD3<Double>) -> matrix_double4x4 {
    let matrix = rotationMatrix(x: rotation.x)
    * rotationMatrix(y: rotation.y)
    * rotationMatrix(z: rotation.z)
    return matrix
  }
  
  public static func rotationMatrix(_ radians: Float, around axis: Axis) -> matrix_float4x4 {
    switch axis {
      case .x:
        return rotationMatrix(x: radians)
      case .y:
        return rotationMatrix(y: radians)
      case .z:
        return rotationMatrix(z: radians)
    }
  }
  
  public static func rotationMatrix(_ radians: Double, around axis: Axis) -> matrix_double4x4 {
    switch axis {
      case .x:
        return rotationMatrix(x: radians)
      case .y:
        return rotationMatrix(y: radians)
      case .z:
        return rotationMatrix(z: radians)
    }
  }
  
  public static func rotationMatrix(x: Float) -> matrix_float4x4 {
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
  
  public static func rotationMatrix(x: Double) -> matrix_double4x4 {
    var matrix = matrix_double4x4(1)
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
  
  public static func rotationMatrix(y: Float) -> matrix_float4x4 {
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
  
  public static func rotationMatrix(y: Double) -> matrix_double4x4 {
    var matrix = matrix_double4x4(1)
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
  
  public static func rotationMatrix(z: Float) -> matrix_float4x4 {
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
  
  public static func rotationMatrix(z: Double) -> matrix_double4x4 {
    var matrix = matrix_double4x4(1)
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
  
  public static func rotationMatrix2d(_ angle: Float) -> matrix_float2x2 {
    return matrix_float2x2(
      [cos(angle), -sin(angle)],
      [sin(angle), cos(angle)]
    )
  }
  
  public static func rotationMatrix2d(_ angle: Double) -> matrix_double2x2 {
    return matrix_double2x2(
      [cos(angle), -sin(angle)],
      [sin(angle), cos(angle)]
    )
  }
  
  public static func matrix4x4to3x3(_ matrix: matrix_float4x4) -> matrix_float3x3 {
    return matrix_float3x3([
      [
        matrix.columns.0.x,
        matrix.columns.0.y,
        matrix.columns.0.z
      ],
      [
        matrix.columns.1.x,
        matrix.columns.1.y,
        matrix.columns.1.z
      ],
      [
        matrix.columns.2.x,
        matrix.columns.2.y,
        matrix.columns.2.z
      ]
    ])
  }
  
  public static func matrix4x4to3x3(_ matrix: matrix_double4x4) -> matrix_double3x3 {
    return matrix_double3x3([
      [
        matrix.columns.0.x,
        matrix.columns.0.y,
        matrix.columns.0.z
      ],
      [
        matrix.columns.1.x,
        matrix.columns.1.y,
        matrix.columns.1.z
      ],
      [
        matrix.columns.2.x,
        matrix.columns.2.y,
        matrix.columns.2.z
      ]
    ])
  }
}
