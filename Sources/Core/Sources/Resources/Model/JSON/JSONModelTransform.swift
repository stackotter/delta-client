import Foundation
import FirebladeMath

/// Transformation that can be applied to a model, as read from JSON files in resource packs.
/// Translation is applied before rotation.
struct JSONModelTransform: Codable {
  /// The rotation (should be `[x, y, z]`).
  var rotation: [Double]?
  /// The translation (should be `[x, y, z]`). Clamp to between -80 and 80.
  var translation: [Double]?
  /// The scale (should be `[x, y, z]`). Maximum 4.
  var scale: [Double]?

  /// Returns a transformation matrix representing this transform.
  func toMatrix() throws -> Mat4x4f {
    var matrix = MatrixUtil.identity

    if let translation = self.translation {
      var translationVector = try MathUtil.vectorFloat3(from: translation)
      translationVector = MathUtil.clamp(translationVector, min: -80, max: 80)
      matrix *= MatrixUtil.translationMatrix(translationVector)
    }

    if let rotation = self.rotation {
      var rotationVector = try MathUtil.vectorFloat3(from: rotation)
      rotationVector = MathUtil.radians(from: rotationVector)
      matrix *= MatrixUtil.rotationMatrix(rotationVector)
    }

    if let scale = self.scale {
      var scaleVector = try MathUtil.vectorFloat3(from: scale)
      scaleVector = MathUtil.clamp(scaleVector, min: -Float.greatestFiniteMagnitude, max: 4)
      matrix *= MatrixUtil.scalingMatrix(scaleVector)
    }

    return matrix
  }
}
