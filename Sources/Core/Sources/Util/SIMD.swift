import simd

extension SIMD3 {
  /// Returns the requested component of the vector.
  /// - Parameter axis: The axis of the component.
  /// - Returns: The value of the requested component.
  func component(along axis: Axis) -> Scalar {
    switch axis {
      case .x: return x
      case .y: return y
      case .z: return z
    }
  }
}

extension SIMD where Scalar: BinaryFloatingPoint {
  /// The magnitude of the vector.
  var magnitude: Scalar {
    sqrt(magnitudeSquared)
  }

  /// The squared magnitude of the vector (use when you're using magnitude purely for comparison because it's faster).
  var magnitudeSquared: Scalar {
    var magnitudeSquared: Scalar = 0
    for i in 0..<scalarCount {
      let component = self[i]
      magnitudeSquared += component * component
    }
    return magnitudeSquared
  }
}
