extension String: GUIElement {
  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    return (try? GUIElementMesh(
      text: self,
      font: context.font,
      fontArrayTexture: context.fontArrayTexture
    )).map { [$0] } ?? []
  }
}
