import FirebladeMath

struct GUIList: GUIElement {
  var items: [GUIListItem]
  var rowHeight: Int
  var renderRowBackground: Bool

  init(rowHeight: Int, renderRowBackground: Bool = false) {
    items = []
    self.rowHeight = rowHeight
    self.renderRowBackground = renderRowBackground
  }

  mutating func add(_ element: GUIElement) {
    items.append(.element(element))
  }

  mutating func add(spacer height: Int) {
    items.append(.spacer(height))
  }

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var bgMeshes: [GUIElementMesh] = []
    var meshes: [GUIElementMesh] = []
    var currentY = 0

    for item in items {
      switch item {
        case .element(let element):
          var elementMeshes = try element.meshes(context: context)
          elementMeshes.translate(amount: [0, currentY])

          if renderRowBackground {
            let bgSize: Vec2i = [elementMeshes.size().x + 1, rowHeight]
            var bg = GUIRectangle(
              size: bgSize,
              color: [0x50, 0x50, 0x50, 0x90] / 255
            ).meshes(context: context)
            bg.translate(amount: [-1, currentY - 1])
            bgMeshes.append(contentsOf: bg)
          }

          meshes.append(contentsOf: elementMeshes)
          currentY += rowHeight
        case .spacer(let height):
          currentY += height
      }
    }

    return bgMeshes + meshes
  }
}
