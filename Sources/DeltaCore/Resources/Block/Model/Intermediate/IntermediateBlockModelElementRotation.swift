import Foundation
import simd

/// A neatened format for `JSONBlockModelElementRotation`.
public struct IntermediateBlockModelElementRotation {
  /// The point to rotate around.
  var origin: simd_float3
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
    degrees = degrees - (degrees.truncatingRemainder(dividingBy: 22.5))
    radians = MathUtil.radians(from: Float(degrees))
    
    // TODO: fix element rotation direction
    
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
  var matrix: matrix_float4x4 {
    var matrix = MatrixUtil.translationMatrix(-origin)
    
    matrix *= MatrixUtil.rotationMatrix(radians, around: axis)
    if rescale {
      let scale = 1/cos(radians)
      print("scale: \(scale), angle: \(MathUtil.degrees(from: radians))")
      matrix *= MatrixUtil.scalingMatrix(
        axis == .x ? 1 : scale,
        axis == .y ? 1 : scale,
        axis == .z ? 1 : scale)
    }
    
    matrix *= MatrixUtil.translationMatrix(origin)
    return matrix
  }
}
