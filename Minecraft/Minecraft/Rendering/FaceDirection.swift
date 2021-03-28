//
//  FaceDirection.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 27/3/21.
//

import Foundation
import simd
import os

enum FaceDirection: String, Codable {
  case down = "down"
  case up = "up"
  case north = "north"
  case south = "south"
  case west = "west"
  case east = "east"
  
  static var directions: [FaceDirection] {
    return [.down, .up, .north, .south, .west, .east]
  }
  
  var axis: Axis {
    switch self {
      case .west, .east:
        return .x
      case .up, .down:
        return .y
      case .north, .south:
        return .z
    }
  }
  
  var opposite: FaceDirection {
    switch self {
      case .down:
        return .up
      case .up:
        return .down
      case .north:
        return .south
      case .south:
        return .north
      case .east:
        return .west
      case .west:
        return .east
    }
  }
  
  func toVector() -> simd_float3 {
    switch self {
      case .down:
        return simd_float3(0, -1, 0)
      case .up:
        return simd_float3(0, 1, 0)
      case .north:
        return simd_float3(0, 0, -1)
      case .south:
        return simd_float3(0, 0, 1)
      case .west:
        return simd_float3(-1, 0, 0)
      case .east:
        return simd_float3(1, 0, 0)
    }
  }
  
  static func fromVector(vector: simd_float3) -> FaceDirection {
    let x = vector.x.rounded()
    let y = vector.y.rounded()
    let z = vector.z.rounded()
    
    if x == 1 {
      return .east
    } else if x == -1 {
      return .west
    } else if z == 1 {
      return .south
    } else if z == -1 {
      return .north
    } else if y == 1 {
      return .up
    } else if y == -1 {
      return .down
    }
    
    Logger.debug("vector \(vector) did not match a direction")
    return .up
  }
}
