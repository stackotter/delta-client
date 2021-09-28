//
//  MathUtil.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/4/21.
//

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
  public static func radians(from degrees: simd_float3) -> simd_float3 {
    return .pi * degrees / 180
  }
  
  /// Converts the given angle to degrees from radians.
  public static func degrees(from radians: simd_float3) -> simd_float3 {
    return 180 * radians / .pi
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
  public static func vectorFloat3(from doubleArray: [Double]) throws -> simd_float3 {
    guard doubleArray.count == 3 else {
      throw MathError.invalidVector
    }
    
    return simd_float3(doubleArray.map { Float($0) })
  }
  
  // TODO: use swift numerics package instead
  public static func checkFloatEquality(_ a: Float, _ b: Float, absoluteTolerance: Float) -> Bool {
    return abs(a - b) <= absoluteTolerance
  }
  
  public static func checkFloatLessThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    return a - b < absoluteTolerance
  }
  
  public static func checkFloatGreaterThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    return b - a < absoluteTolerance
  }
}
