struct GUIList: GUIElement {
  var items: [GUIListItem]
  var rowHeight: Int

  init(rowHeight: Int) {
    items = []
    self.rowHeight = rowHeight
  }

  mutating func add(_ element: GUIElement) {
    items.append(.element(element))
  }

  mutating func add(spacer height: Int) {
    items.append(.spacer(height))
  }

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var meshes: [GUIElementMesh] = []
    var currentY = 0
    for item in items {
      switch item {
        case .element(let element):
          var elementMeshes = try element.meshes(context: context)
          elementMeshes.translate(amount: [0, currentY])
          meshes.append(contentsOf: elementMeshes)
          currentY += rowHeight
        case .spacer(let height):
          currentY += height
      }
    }
    return meshes
  }
}
