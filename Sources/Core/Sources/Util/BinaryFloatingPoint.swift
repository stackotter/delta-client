import Darwin

public extension Double {
  func rounded(toPlaces places: Int) -> Double {
    let shift = pow(10, Double(places))
    return (self * shift).rounded() / shift
  }
}

public extension Float {
  func rounded(toPlaces places: Int) -> Float {
    let shift = pow(10, Float(places))
    return (self * shift).rounded() / shift
  }
}
