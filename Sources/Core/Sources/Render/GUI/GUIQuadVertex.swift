import simd

/// A vertex in a gui quad.
struct GUIQuadVertex {
  /// The position.
  var position: SIMD2<Float>
  /// The uv.
  var uv: SIMD2<Float>
}
