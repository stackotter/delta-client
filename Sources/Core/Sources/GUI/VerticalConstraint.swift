public enum VerticalConstraint {
  case top(Int)
  case center(VerticalOffset?)
  case bottom(Int)

  public static let center = Self.center(nil)
}
