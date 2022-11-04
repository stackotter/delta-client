extension String: GUIElement {
  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    let builder = TextMeshBuilder(font: context.font)
    return try builder.build(
      self,
      fontArrayTexture: context.fontArrayTexture
    ).map { [$0] } ?? []
  }
}
