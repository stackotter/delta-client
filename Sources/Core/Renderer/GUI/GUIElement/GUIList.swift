import FirebladeMath

struct GUIList: GUIElement {
  var items: [GUIListItem]
  var rowHeight: Int
  var renderRowBackground: Bool
  var rightAlign: Bool

  init(rowHeight: Int, renderRowBackground: Bool = false, rightAlign: Bool = false) {
    items = []
    self.rowHeight = rowHeight
    self.renderRowBackground = renderRowBackground
    self.rightAlign = rightAlign
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
    var processedItems: [(GUIListItem, [GUIElementMesh])] = []
    var maxWidth = 0
    var currentY = 0

    // block to find longest row of elements 
    for item in items {
      switch item {
        case .element(let element):
          let elementMeshes = try element.meshes(context: context)
          processedItems.append((item, elementMeshes))
          if elementMeshes.size().x > maxWidth {
            maxWidth = elementMeshes.size().x
          }
        case .spacer:
          processedItems.append((item, []))
      }
    }

    for (item, var elementMeshes) in processedItems {
      switch item {
        case .element:
          switch rightAlign {
            case false:
              elementMeshes.translate(amount: [0, currentY])
            case true:
              elementMeshes.translate(amount: [maxWidth - elementMeshes.size().x, currentY])
          }

          if renderRowBackground {
            let bgSize: Vec2i = [elementMeshes.size().x + 2, rowHeight]
            var bg = GUIRectangle(
              size: bgSize,
              color: [0x50, 0x50, 0x50, 0x90] / 255
            ).meshes(context: context)
            switch rightAlign {
              case false:
                bg.translate(amount: [-1, currentY - 1])
              case true:
                bg.translate(amount: [maxWidth - elementMeshes.size().x - 1, currentY - 1])
            }
            
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
