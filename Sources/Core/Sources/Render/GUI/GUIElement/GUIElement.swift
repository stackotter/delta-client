protocol GUIElement {
  func meshes(context: GUIContext) throws -> [GUIElementMesh]
}
