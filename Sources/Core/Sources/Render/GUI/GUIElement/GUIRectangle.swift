/// A solid colored rectangle.
struct GUIRectangle: GUIElement {
  var size: SIMD2<Int>
  var color: SIMD4<Float>

  func meshes(context: GUIContext) -> [GUIElementMesh] {
    return [GUIElementMesh(
      size: size,
      arrayTexture: nil,
      quads: [GUIQuad(
        position: .zero,
        size: SIMD2(size),
        color: color
      )]
    )]
  }
}
