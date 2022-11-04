import FirebladeMath

struct GUIColoredString: GUIElement {
  var text: String
  var color: Vec4f
  var outlineColor: Vec4f?

  init(_ text: String, _ color: Vec4f, outlineColor: Vec4f? = nil) {
    self.text = text
    self.color = color
    self.outlineColor = outlineColor
  }

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    let builder = TextMeshBuilder(font: context.font)
    return try builder.build(
      text,
      fontArrayTexture: context.fontArrayTexture,
      color: color,
      outlineColor: outlineColor
    ).map { [$0] } ?? []
  }
}
