import FirebladeMath

extension Array where Element == GUIElementMesh {
  mutating func translate(amount: Vec2i) {
    for i in 0..<count {
      self[i].position &+= amount
    }
  }

  func size() -> Vec2i {
    var iterator = makeIterator()
    guard let first = iterator.next() else {
      return [0, 0]
    }

    var minX = first.position.x
    var maxX = minX + first.size.x
    var minY = first.position.y
    var maxY = minY + first.size.y

    while let mesh = iterator.next() {
      let position = mesh.position
      let size = mesh.size
      let meshMaxX = position.x + size.x
      let meshMaxY = position.y + size.y
      if meshMaxX > maxX {
        maxX = meshMaxX
      }
      if position.x < minX {
        minX = position.x
      }
      if meshMaxY > maxY {
        maxY = meshMaxY
      }
      if position.y < minY {
        minY = position.y
      }
    }

    return [maxX - minX, maxY - minY]
  }
}
