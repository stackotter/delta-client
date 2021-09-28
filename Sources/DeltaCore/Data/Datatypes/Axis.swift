//
//  Axis.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 27/3/21.
//

import Foundation

/// An axis
public enum Axis {
  case x
  case y
  case z
  
  /// The positive direction along this axis in Minecraft's coordinate system.
  public var positiveDirection: Direction {
    switch self {
      case .x:
        return .east
      case .y:
        return .up
      case .z:
        return .south
    }
  }
  
  /// The negative direction along this axis in Minecraft's coordinate system.
  public var negativeDirection: Direction {
    switch self {
      case .x:
        return .west
      case .y:
        return .down
      case .z:
        return .north
    }
  }
}
