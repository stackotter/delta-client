import simd

extension Array where Element == GUIElementMesh {
  mutating func translate(amount: SIMD2<Int>) {
    for (i, var mesh) in self.enumerated() {
      mesh.position &+= amount
      self[i] = mesh
    }
  }

  func size() -> SIMD2<Int> {
    var minX = Int.max
    var maxX = Int.min
    var minY = Int.max
    var maxY = Int.min
    for mesh in self {
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
