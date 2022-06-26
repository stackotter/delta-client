import simd

/// The GUI's uniforms.
public struct GUIUniforms {
  /// The transformation to convert screen space coordinates to normalized device coordinates.
  var screenSpaceToNormalized: simd_float3x3
  /// The GUI scale.
  var scale: Float
}
