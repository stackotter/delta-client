import simd

/// A vertex in the GUI.
struct GUIVertex {
  /// The position.
  var position: SIMD2<Float>
  /// The uv coordinate.
  var uv: SIMD2<Float>
  /// The color to tint the vertex.
  var tint: SIMD4<Float>
  /// The index of the texture in the array texture. If equal to ``UInt16/max``, no texture is
  /// sampled and the fragment color will be equal to the tint.
  var textureIndex: UInt16
}
