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
}
