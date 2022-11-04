enum HorizontalConstraint {
  case left(Int)
  case center(HorizontalOffset?)
  case right(Int)

  static let center = Self.center(nil)
}
