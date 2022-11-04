import FirebladeMath

/// A vertex in the GUI.
struct GUIVertex: Equatable {
  /// The position.
  var position: Vec2f
  /// The uv coordinate.
  var uv: Vec2f
  /// The color to tint the vertex.
  var tint: Vec4f
  /// The index of the texture in the array texture. If equal to ``UInt16/max``, no texture is
  /// sampled and the fragment color will be equal to the tint.
  var textureIndex: UInt16
}
