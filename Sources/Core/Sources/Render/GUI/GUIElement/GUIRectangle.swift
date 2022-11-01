import FirebladeMath

/// A solid colored rectangle.
struct GUIRectangle: GUIElement {
  var size: Vec2i
  var color: Vec4f

  func meshes(context: GUIContext) -> [GUIElementMesh] {
    return [GUIElementMesh(
      size: size,
      arrayTexture: nil,
      quads: [GUIQuad(
        position: .zero,
        size: Vec2f(size),
        color: color
      )]
    )]
  }
}
