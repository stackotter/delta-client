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
    var processedItems: [(item: GUIListItem, meshes: [GUIElementMesh], size: Vec2i)] = []
    var maxWidth = 0
    var currentY = 0

    // Find the widest element while caching meshes to prevent generating them twice
    for item in items {
      switch item {
        case .element(let element):
          let elementMeshes = try element.meshes(context: context)
          let size = elementMeshes.size()
          if size.x > maxWidth {
            maxWidth = size.x
          }

          processedItems.append((item: item, meshes: elementMeshes, size: size))
        case .spacer:
          processedItems.append((item: item, meshes: [], size: [0, 0]))
      }
    }

    for (i, (item, _, size)) in processedItems.enumerated() {
      switch item {
        case .element:
          switch alignment {
            case .left:
              processedItems[i].meshes.translate(amount: [0, currentY])
            case .right:
              processedItems[i].meshes.translate(amount: [maxWidth - size.x, currentY])
          }

          if renderRowBackground {
            let bgSize: Vec2i = [size.x + 2, rowHeight]
            var bg = GUIRectangle(
              size: bgSize,
              color: [0x50, 0x50, 0x50, 0x90] / 255
            ).meshes(context: context)

            switch alignment {
              case .left:
                bg.translate(amount: [-1, currentY - 1])
              case .right:
                bg.translate(amount: [maxWidth - size.x - 1, currentY - 1])
            }

            bgMeshes.append(contentsOf: bg)
          }

          meshes.append(contentsOf: processedItems[i].meshes)
          currentY += rowHeight
        case .spacer(let height):
          currentY += height
      }
    }

    return bgMeshes + meshes
  }
}
