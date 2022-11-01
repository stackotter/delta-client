import FirebladeMath

extension Matrix2x2 {
  init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}

extension Matrix3x3 {
  init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}

extension Matrix4x4 {
  init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}
