//
//  FaceDirection.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/3/21.
//

import Foundation
import simd

enum FaceDirection: Int {
  case up = 0
  case down = 1
  case north = 2
  case south = 3
  case east = 4
  case west = 5
  
  static var allDirections: [FaceDirection] = [
    .down,
    .up,
    .north,
    .south,
    .west,
    .east]
  
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
  
  init?(fromCache cache: CacheFaceDirection) {
    switch cache {
      case .down:
        self = .down
      case .up:
        self = .up
      case .south:
        self = .south
      case .north:
        self = .north
      case .east:
        self = .east
      case .west:
        self = .west
      default:
        return nil
    }
  }
  
  init?(string: String) {
    switch string {
      case "down":
        self = .down
      case "up":
        self = .up
      case "north":
        self = .north
      case "south":
        self = .south
      case "west":
        self = .west
      case "east":
        self = .east
      default:
        return nil
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
    
    log.warning("vector \(vector) did not match a direction")
    return .up
  }
  
  func rotated(_ rotationMatrix: matrix_float4x4) -> FaceDirection {
    let vector = simd_float4(self.toVector(), 1) * rotationMatrix
    return FaceDirection.fromVector(vector: simd_make_float3(vector))
  }
  
  func toCache() -> CacheFaceDirection {
    switch self {
      case .down:
        return CacheFaceDirection.down
      case .up:
        return CacheFaceDirection.up
      case .south:
        return CacheFaceDirection.south
      case .north:
        return CacheFaceDirection.north
      case .east:
        return CacheFaceDirection.east
      case .west:
        return CacheFaceDirection.west
    }
  }
}
