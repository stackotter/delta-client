import FirebladeMath

public struct Constraints {
  public var vertical: VerticalConstraint
  public var horizontal: HorizontalConstraint

  public init(_ vertical: VerticalConstraint, _ horizontal: HorizontalConstraint) {
    self.vertical = vertical
    self.horizontal = horizontal
  }

  public static let center = Constraints(.center, .center)

  public static func position(_ x: Int, _ y: Int) -> Constraints {
    return Constraints(.top(y), .left(x))
  }

  public func solve(innerSize: Vec2i, outerSize: Vec2i) -> Vec2i {
    let x: Int
    switch horizontal {
      case .left(let distance):
        x = distance
      case .center(let offset):
        x = (outerSize.x - innerSize.x) / 2 + (offset?.value ?? 0)
      case .right(let distance):
        x = outerSize.x - innerSize.x - distance
    }

    let y: Int
    switch vertical {
      case .top(let distance):
        y = distance
      case .center(let offset):
        y = (outerSize.y - innerSize.y) / 2 + (offset?.value ?? 0)
      case .bottom(let distance):
        y = outerSize.y - innerSize.y - distance
    }

    return [x, y]
  }
}
