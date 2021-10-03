import Foundation
import simd

/// A neater format for `PixlyzerBlockModelDescriptor`.
public struct BlockModelRenderDescriptor {
  public var model: Identifier
  public var xRotationDegrees: Int
  public var yRotationDegrees: Int
  public var uvLock: Bool
  
  public init(model: Identifier, xRotationDegrees: Int, yRotationDegrees: Int, uvLock: Bool) {
    self.model = model
    self.xRotationDegrees = xRotationDegrees
    self.yRotationDegrees = yRotationDegrees
    self.uvLock = uvLock
  }
  
  public init(from pixlyzerDescriptor: PixlyzerBlockModelDescriptor) {
    model = pixlyzerDescriptor.model
    xRotationDegrees = pixlyzerDescriptor.xRotation ?? 0
    yRotationDegrees = pixlyzerDescriptor.yRotation ?? 0
    uvLock = pixlyzerDescriptor.uvLock ?? false
  }
  
  /// Transformation matrix that rotates around the center of the block (`[0.5, 0.5, 0.5]`).
  var transformationMatrix: matrix_float4x4 {
    // Apply the rotation, rotating around the center of the block
    let origin = SIMD3<Float>(repeating: 0.5)
    let matrix = MatrixUtil.translationMatrix(-origin)
      * rotationMatrix
      * MatrixUtil.translationMatrix(origin)
    
    return matrix
  }
  
  /// Only the rotation component of the transformation.
  var rotationMatrix: matrix_float4x4 {
    // Create a vector for the rotation
    let rotationDegrees = SIMD3<Float>(
      Float(xRotationDegrees),
      Float(yRotationDegrees),
      0)
    
    let rotation = MathUtil.radians(from: rotationDegrees)
    return MatrixUtil.rotationMatrix(rotation)
  }
}
