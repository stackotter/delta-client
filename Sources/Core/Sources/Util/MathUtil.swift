import Foundation
import FirebladeMath

public enum MathError: LocalizedError {
  case invalidVectorLength(_ length: Int)

  public var errorDescription: String? {
    switch self {
      case .invalidVectorLength(let elementsCount):
        return "Invalid 3D vector. 3D vector should have exactly 3 elements, but got \(elementsCount) instead."
    }
  }
}

/// Some utility functions to do with maths.
public enum MathUtil {
  /// Converts the given angle to radians from degrees.
  public static func radians<T: FloatingPoint>(from degrees: T) -> T {
    return .pi * degrees / 180
  }

  /// Converts the given angle to degrees from radians.
  public static func degrees<T: FloatingPoint>(from radians: T) -> T {
    return 180 * radians / .pi
  }

  /// Converts the given angle to radians from degrees.
  public static func radians(from degrees: Vec3f) -> Vec3f {
    return .pi * degrees / 180
  }

  /// Converts the given angle to degrees from radians.
  public static func degrees(from radians: Vec3f) -> Vec3f {
    return 180 * radians / .pi
  }

  /// Linearly interpolates between two floating point values.
  /// - Parameters:
  ///   - initial: The initial value.
  ///   - target: The target value.
  ///   - progress: The progress from the initial value to the target value (gets clamped between 0 and 1).
  /// - Returns: The current value, linearly interpolated between the initial and target values.
  public static func lerp<T: FloatingPoint>(from initial: T, to target: T, progress: T) -> T {
    let progress = MathUtil.clamp(progress, 0, 1)
    return initial + progress * (target - initial)
  }

  // Linearly interpolates the individual components of two vectors.
  public static func lerp<T: FloatingPoint>(from initial: Vec3<T>, to target: Vec3<T>, progress: T) -> Vec3<T> {
    return Vec3(
      lerp(from: initial.x, to: target.x, progress: progress),
      lerp(from: initial.y, to: target.y, progress: progress),
      lerp(from: initial.z, to: target.z, progress: progress)
    )
  }

  /// Linearly interpolates between two angles (in radians).
  /// - Parameters:
  ///   - initial: The initial angle in radians.
  ///   - target: The target angle in radians.
  ///   - progress: The progress from the initial angle to the target angle (gets clamped between 0 and 1).
  /// - Returns: The current angle, linearly interpolated between the initial and target angles.
  public static func lerpAngle<T: FloatingPoint>(from initial: T, to target: T, progress: T) -> T {
    let max: T = .pi * 2
    // Difference is the smallest angle between the initial and target angles (for example, lerping from 359 degrees to 0, the difference would be 1)
    var difference = (target - initial).remainder(dividingBy: max)
    difference = (2 * difference).remainder(dividingBy: max) - difference
    let progress = MathUtil.clamp(progress, 0, 1)
    return initial + progress * difference
  }

  /// Calculates `a` (mod `n`). `n` must be positive.
  ///
  /// Swift's `%` isn't actually mod, it is remainder and doesn't behave the
  /// same way for negative numbers. See https://stackoverflow.com/a/41180619
  public static func mod(_ a: Int, _ n: Int) -> Int {
    precondition(n > 0, "Modulus must be positive")
    let r = a % n
    return r >= 0 ? r : r + n
  }

  /// Converts an array of doubles to a 3d vector. Throws if the array doesn't have exactly 3 elements.
  public static func vectorFloat3(from doubleArray: [Double]) throws -> Vec3f {
    guard doubleArray.count == 3 else {
      throw MathError.invalidVectorLength(doubleArray.count)
    }

    return Vec3f(doubleArray.map { Float($0) })
  }

  /// Checks for approximate equality between two floats.
  /// - Parameters:
  ///   - a: The first float.
  ///   - b: The second float.
  ///   - absoluteTolerance: The tolerance for what is acceptable equality.
  /// - Returns: The approximate equality.
  public static func checkFloatEquality(_ a: Float, _ b: Float, absoluteTolerance: Float) -> Bool {
    // TODO: use swift numerics package instead
    return Swift.abs(a - b) <= absoluteTolerance
  }

  public static func checkFloatLessThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    // TODO: use swift numerics package instead
    return a - b < absoluteTolerance
  }

  public static func checkFloatGreaterThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    // TODO: use swift numerics package instead
    return b - a < absoluteTolerance
  }

  /// Clamps a given value between a maximum and minimum value.
  /// - Parameters:
  ///   - value: The value to clamp.
  ///   - minValue: The minimum value.
  ///   - maxValue: The maximum value.
  /// - Returns: The clamped value.
  @_specialize(where T:_Trivial)
  public static func clamp<T>(_ value: T, _ minValue: T, _ maxValue: T) -> T where T: Comparable {
    // TODO: Add `min` and `max` labels to clamp for clarity
    return Swift.min(Swift.max(value, minValue), maxValue)
  }

  /// Clamps the components of a given vector between a maximum and minimum value.
  /// - Parameters:
  ///   - vector: The vector to clamp.
  ///   - minValue: The minimum value.
  ///   - maxValue: The maximum value.
  /// - Returns: The clamped value.
  @_specialize(where T:_Trivial)
  public static func clamp<T: SIMD>(_ vector: T, min minValue: T.Scalar, max maxValue: T.Scalar) -> T where T.Scalar: Comparable {
    var vector = vector
    for i in vector.indices {
      vector[i] = Swift.min(Swift.max(vector[i], minValue), maxValue)
    }
    return vector
  }

  @_specialize(where T:_Trivial)
  public static func min<T: SIMD>(_ vector: T, _ other: T) -> T where T.Scalar: Comparable {
    var out = vector
    for i in vector.indices {
      out[i] = Swift.min(vector[i], other[i])
    }
    return out
  }

  @_specialize(where T:_Trivial)
  public static func max<T: SIMD>(_ vector: T, _ other: T) -> T where T.Scalar: Comparable {
    var out = vector
    for i in vector.indices {
      out[i] = Swift.max(vector[i], other[i])
    }
    return out
  }

  /// Takes the absolute value of each element of a vector.
  /// - Parameters:
  ///   - vector: The vector.
  /// - Returns: The absolute vector.
  @_specialize(where T:_Trivial)
  public static func abs<T: SIMD>(_ vector: T) -> T where T.Scalar: Comparable & SignedNumeric {
    var vector = vector
    for i in vector.indices {
      vector[i] = Swift.abs(vector[i])
    }
    return vector
  }

  /// Computes a vector containing the sign of each component.
  /// - Parameters:
  ///   - vector: The vector.
  /// - Returns: The absolute vector.
  public static func sign<T: SIMD>(_ vector: T) -> T where T.Scalar == Float {
    var vector = vector
    for i in vector.indices {
      vector[i] = FirebladeMath.sign(vector[i])
    }
    return vector
  }
}
