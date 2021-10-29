import Foundation
import simd

public struct Uniforms {
  public var transformation: matrix_float4x4
  
  public init(transformation: matrix_float4x4) {
    self.transformation = transformation
  }
  
  public init() {
    transformation = matrix_float4x4(1)
  }
}
