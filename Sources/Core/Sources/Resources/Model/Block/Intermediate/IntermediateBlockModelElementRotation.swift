import Foundation
import FirebladeMath

/// A neatened format for `JSONBlockModelElementRotation`.
struct IntermediateBlockModelElementRotation {
  /// The point to rotate around.
  var origin: Vec3f
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
    degrees -= (degrees.truncatingRemainder(dividingBy: 22.5))
    radians = MathUtil.radians(from: Float(degrees))

    // For some reason in our renderer we need x and y rotation to be reversed but only
    // for rotations from mojang block model files everything else is fine?
    switch axis {
      case .x, .y:
        radians = -radians
      case .z:
        break
    }
  }

  /// Returns a transformation matrix representing this rotation.
  var matrix: Mat4x4f {
    var matrix = MatrixUtil.translationMatrix(-origin)

    matrix *= MatrixUtil.rotationMatrix(radians, around: axis)
    if rescale {
      let scale = 1 / Foundation.cos(radians)
      matrix *= MatrixUtil.scalingMatrix(
        axis == .x ? 1 : scale,
        axis == .y ? 1 : scale,
        axis == .z ? 1 : scale
      )
    }

    matrix *= MatrixUtil.translationMatrix(origin)
    return matrix
  }
}
