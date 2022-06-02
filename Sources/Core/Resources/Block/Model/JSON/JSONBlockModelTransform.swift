import Foundation
import simd

/// Block model transform as read from block model json file in resource packs.
/// Translation is applied before rotation.
public struct JSONBlockModelTransform: Codable {
  /// The rotation (should be `[x, y, z]`).
  public var rotation: [Double]?
  /// The translation (should be `[x, y, z]`). Clamp to between -80 and 80.
  public var translation: [Double]?
  /// The scale (should be `[x, y, z]`). Maximum 4.
  public var scale: [Double]?
  
  /// Returns a transformation matrix representing this transform.
  public func toMatrix() throws -> matrix_float4x4 {
    var matrix = MatrixUtil.identity
    
    if let translation = self.translation {
      var translationVector = try MathUtil.vectorFloat3(from: translation)
      translationVector = clamp(translationVector, min: -80, max: 80)
      matrix *= MatrixUtil.translationMatrix(translationVector)
    }
    
    if let rotation = self.rotation {
      var rotationVector = try MathUtil.vectorFloat3(from: rotation)
      rotationVector = MathUtil.radians(from: rotationVector)
      matrix *= MatrixUtil.rotationMatrix(rotationVector)
    }
    
    if let scale = self.scale {
      var scaleVector = try MathUtil.vectorFloat3(from: scale)
      scaleVector = clamp(scaleVector, min: -Float.greatestFiniteMagnitude, max: 4)
      matrix *= MatrixUtil.scalingMatrix(scaleVector)
    }
    
    return matrix
  }
}
