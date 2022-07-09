import simd

struct GUIColoredString: GUIElement {
  var text: String
  var color: SIMD3<Float>
  var outlineColor: SIMD3<Float>?

  init(_ text: String, _ color: SIMD3<Float>, outlineColor: SIMD3<Float>? = nil) {
    self.text = text
    self.color = color
    self.outlineColor = outlineColor
  }

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    return [try GUIElementMesh(
      text: text,
      font: context.font,
      fontArrayTexture: context.fontArrayTexture,
      color: color,
      outlineColor: outlineColor
    )]
  }
}
