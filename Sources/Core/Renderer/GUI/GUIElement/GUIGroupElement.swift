import FirebladeMath

struct GUIGroupElement: GUIElement {
  var size: Vec2i
  var children: [(GUIElement, Constraints)]

  init(_ size: Vec2i) {
    self.size = size
    children = []
  }

  mutating func add(_ element: GUIElement, _ constraints: Constraints) {
    children.append((element, constraints))
  }

  mutating func add(
    _ element: GUIElement,
    _ vertical: VerticalConstraint,
    _ horizontal: HorizontalConstraint
  ) {
    children.append((element, Constraints(vertical, horizontal)))
  }

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var meshes: [GUIElementMesh] = []
    for (element, constraints) in children {
      var elementMeshes = try element.meshes(context: context)

      let elementSize: Vec2i
      if let group = element as? GUIGroupElement {
        elementSize = group.size
      } else {
        elementSize = elementMeshes.size()
      }

      let offset = constraints.solve(innerSize: elementSize, outerSize: size)
      for i in 0..<elementMeshes.count {
        elementMeshes[i].position &+= offset
      }

      meshes.append(contentsOf: elementMeshes)
    }

    return meshes
  }
}
