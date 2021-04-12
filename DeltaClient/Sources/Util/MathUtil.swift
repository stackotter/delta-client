//
//  MathUtil.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/4/21.
//

import Foundation

struct MathUtil {
  static func checkFloatEquality(_ a: Float, _ b: Float, absoluteTolerance: Float) -> Bool {
    return abs(a - b) <= absoluteTolerance
  }
  
  static func checkFloatLessThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    return a - b < absoluteTolerance
  }
  
  static func checkFloatGreaterThan(value a: Float, compareTo b: Float, absoluteTolerance: Float) -> Bool {
    return b - a < absoluteTolerance
  }
}
