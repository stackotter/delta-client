import simd

struct Constraints {
  var vertical: VerticalConstraint
  var horizontal: HorizontalConstraint

  init(_ vertical: VerticalConstraint, _ horizontal: HorizontalConstraint) {
    self.vertical = vertical
    self.horizontal = horizontal
  }

  static let center = Constraints(.center, .center)

  static func position(_ x: Int, _ y: Int) -> Constraints {
    return Constraints(.top(y), .left(x))
  }

  func solve(innerSize: SIMD2<Int>, outerSize: SIMD2<Int>) -> SIMD2<Int> {
    let x: Int
    switch horizontal {
      case .left(let distance):
        x = distance
      case .center:
        x = (outerSize.x - innerSize.x) / 2
      case .right(let distance):
        x = outerSize.x - innerSize.x - distance
    }

    let y: Int
    switch vertical {
      case .top(let distance):
        y = distance
      case .center:
        y = (outerSize.y - innerSize.y) / 2
      case .bottom(let distance):
        y = outerSize.y - innerSize.y - distance
    }

    return [x, y]
  }
}
