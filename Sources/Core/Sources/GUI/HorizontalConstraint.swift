public enum HorizontalConstraint {
  case left(Int)
  case center(HorizontalOffset?)
  case right(Int)

  public static let center = Self.center(nil)
}
