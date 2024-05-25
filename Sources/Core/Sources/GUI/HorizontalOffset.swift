public enum HorizontalOffset {
  case left(Int)
  case right(Int)

  /// The offset value, negative for up, positive for down.
  public var value: Int {
    switch self {
      case .left(let offset):
        return -offset
      case .right(let offset):
        return offset
    }
  }
}
