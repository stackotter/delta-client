enum VerticalOffset {
  case up(Int)
  case down(Int)

  /// The offset value, negative for up, positive for down.
  var value: Int {
    switch self {
      case .up(let offset):
        return -offset
      case .down(let offset):
        return offset
    }
  }
}
