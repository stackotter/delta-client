extension Array where Element: BinaryFloatingPoint {
  /// - Returns: The average of an array of floating point values.
  public func average() -> Element {
    isEmpty ? .zero : reduce(into: 0, { $0 += $1 }) / Element(count)
  }
}
