enum VerticalConstraint {
  case top(Int)
  case center(VerticalOffset?)
  case bottom(Int)

  static let center = Self.center(nil)
}
