import FirebladeMath

extension Matrix2x2 {
  public init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}

extension Matrix3x3 {
  public init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}

extension Matrix4x4 {
  public init(diagonal: Value) {
    self.init(diagonal: Vector(repeating: diagonal))
  }
}
