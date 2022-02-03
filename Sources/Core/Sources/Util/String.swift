extension String {
  /// Returns the substring between two substrings.
  ///
  /// Example usage:
  ///
  /// ```swift
  /// let string = "blah, hi: 123: apple"
  /// let slice = string.slice(from: ", hi", to: ": apple")
  /// assert(slice == ": 123")
  /// ```
  func slice(from: String, to: String) -> String? {
    return (range(of: from)?.upperBound).flatMap { substringFrom in
      (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
        String(self[substringFrom..<substringTo])
      }
    }
  }
}
