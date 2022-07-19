import simd

/// A vertex in the GUI.
struct GUIVertex {
  /// The position.
  var position: SIMD2<Float>
  /// The uv coordinate.
  var uv: SIMD2<Float>
  /// The color to tint the vertex.
  var tint: SIMD3<Float>
  /// The index of the texture in the array texture.
  var textureIndex: UInt16
}
