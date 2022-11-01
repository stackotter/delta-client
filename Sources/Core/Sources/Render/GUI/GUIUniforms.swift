import FirebladeMath

/// The GUI's uniforms.
public struct GUIUniforms: Equatable {
  /// The transformation to convert screen space coordinates to normalized device coordinates.
  var screenSpaceToNormalized: Mat3x3f
  /// The GUI scale.
  var scale: Float
}
