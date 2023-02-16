import Foundation
import FirebladeMath

/// Stores the transforms and properties to apply to a model before rendering it. For changes to the
/// block registry's render descriptors to take effect you must force the block model palette to be
/// regenerated, or regenerate it yourself.
///
/// A neater format for ``PixlyzerBlockModelDescriptor``.
public struct BlockModelRenderDescriptor: Codable {
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

  /// Transformation matrix that rotates around the center of the block (`[0.5, 0.5, 0.5]`).
  var transformationMatrix: Mat4x4f {
    // Apply the rotation, rotating around the center of the block
    let origin = Vec3f(repeating: 0.5)
    let matrix = MatrixUtil.translationMatrix(-origin)
      * rotationMatrix
      * MatrixUtil.translationMatrix(origin)

    return matrix
  }

  /// Only the rotation component of the transformation.
  var rotationMatrix: Mat4x4f {
    // Create a vector for the rotation
    let rotationDegrees = Vec3f(
      Float(xRotationDegrees),
      Float(yRotationDegrees),
      0
    )

    let rotation = MathUtil.radians(from: rotationDegrees)
    return MatrixUtil.rotationMatrix(rotation)
  }
}
