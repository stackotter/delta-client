import FirebladeMath

struct GUIList: GUIElement {
  var items: [GUIListItem]
  var rowHeight: Int
  var renderRowBackground: Bool
  var alignment: Alignment
  
  enum Alignment {
    case left
    case right
  }

  init(rowHeight: Int, renderRowBackground: Bool = false, alignment: Alignment = .left) {
    items = []
    self.rowHeight = rowHeight
    self.renderRowBackground = renderRowBackground
    self.alignment = alignment
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
          switch alignment {
            case .left:
              elementMeshes.translate(amount: [0, currentY])
            case .right:
              elementMeshes.translate(amount: [maxWidth - elementMeshes.size().x, currentY])
          }

          if renderRowBackground {
            let bgSize: Vec2i = [elementMeshes.size().x + 2, rowHeight]
            var bg = GUIRectangle(
              size: bgSize,
              color: [0x50, 0x50, 0x50, 0x90] / 255
            ).meshes(context: context)
            switch alignment {
              case .left:
                bg.translate(amount: [-1, currentY - 1])
              case .right:
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
