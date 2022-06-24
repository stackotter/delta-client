import Foundation
import FirebladeMath

public struct Uniforms {
  public var transformation: Mat4x4f
  
  public init(transformation: Mat4x4f) {
    self.transformation = transformation
  }
  
  public init() {
    transformation = Mat4x4f(1)
  }
}
