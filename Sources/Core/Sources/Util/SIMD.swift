import FirebladeMath

extension Vec3 {
  /// Returns the requested component of the vector.
  /// - Parameter axis: The axis of the component.
  /// - Returns: The value of the requested component.
  public func component(along axis: Axis) -> Scalar {
    switch axis {
      case .x: return x
      case .y: return y
      case .z: return z
    }
  }
}

extension Vec where Scalar: BinaryFloatingPoint {
  /// The squared magnitude of the vector (use when you're using magnitude purely for comparison because it's faster).
  public var magnitudeSquared: Scalar {
    var magnitudeSquared: Scalar = 0
    for i in 0..<scalarCount {
      let component = self[i]
      magnitudeSquared += component * component
    }
    return magnitudeSquared
  }
}

extension Vec where Scalar == Float {
  /// The magnitude of the vector.
  public var magnitude: Float {
    sqrt(magnitudeSquared)
  }
}

extension Vec where Scalar == Double {
  /// The magnitude of the vector.
  public var magnitude: Double {
    sqrt(magnitudeSquared)
  }
}
