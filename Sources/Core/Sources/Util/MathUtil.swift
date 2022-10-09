import Foundation
import simd

public enum MathError: LocalizedError {
  case invalidVector
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
  public static func radians(from degrees: SIMD3<Float>) -> SIMD3<Float> {
    return .pi * degrees / 180
  }
  
  /// Converts the given angle to degrees from radians.
  public static func degrees(from radians: SIMD3<Float>) -> SIMD3<Float> {
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
  public static func lerp<T: FloatingPoint>(from initial: SIMD3<T>, to target: SIMD3<T>, progress: T) -> SIMD3<T> {
    return SIMD3(
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
  public static func vectorFloat3(from doubleArray: [Double]) throws -> SIMD3<Float> {
    guard doubleArray.count == 3 else {
      throw MathError.invalidVector
    }
    
    return SIMD3<Float>(doubleArray.map { Float($0) })
  }
  
  /// Checks for approximate equality between two floats.
  /// - Parameters:
  ///   - a: The first float.
  ///   - b: The second float.
  ///   - absoluteTolerance: The tolerance for what is acceptable equality.
  /// - Returns: The approximate equality.
  public static func checkFloatEquality(_ a: Float, _ b: Float, absoluteTolerance: Float) -> Bool {
    // TODO: use swift numerics package instead
    return abs(a - b) <= absoluteTolerance
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
    return min(max(value, minValue), maxValue)
  }
}
